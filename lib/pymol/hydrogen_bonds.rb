require 'pymol'
require 'pymol/connections'

require 'bio/db/pdb'
require 'hydrogen_bondifier/utils'

class Pymol
  EXCLUDE_WATER_FILTER = " &! resn hoh"
  module HydrogenBonds

    DEFAULT_FIND_PAIRS_OPTS = {:max_dist => 3.2, :max_angle => 60, :exclude_water => true }
    DEFAULT_H_BOND_OPTS = {
      :select_donor => "and (elem n,o and (neighbor hydro))",
      :select_acceptor => "and (elem o or (elem n and not (neighbor hydro)))",
    }

    module_function

    def pdb_with_hydrogens(pdb_filename, newname=nil)
      pfile = pdb_filename
      newname = pfile.chomp(File.extname(pfile)) + "_plus_h.pdb" unless newname
      Pymol.run(:msg => 'creating pdb with hydrogens') do |pm|
        pm.cmd "load #{pfile}, mymodel"
        pm.cmd "h_add"
        pm.cmd "save #{newname}"
      end
      newname
    end

    # returns [id1, id2, distance] for each atom
    def find_pairs(file, sel1, sel2, opt={})
      opt = DEFAULT_FIND_PAIRS_OPTS.merge( opt )
      exclude_water_command = opt[:exclude_water] ? EXCLUDE_WATER_FILTER : ""
      hbond_script = Pymol::HydrogenBonds.list_hb_script(sel1, sel2)
      puts hbond_script
      reply = Pymol.run(:msg => "getting hydrogen bonds", :script => hbond_script) do |pm|
        pm.cmd "load #{file}, mymodel"
        pm.cmd "list_hb mymodel#{exclude_water_command}, cutoff=#{opt[:max_dist]}, angle=#{opt[:max_angle]}"
      end
      Pymol::HydrogenBonds.list_hb_parser(reply)
    end


    # returns [donor, hydrogen, acceptor, angle, don_to_acc_dist, h_to_acc_dist]
    # The first three are Bio::PDB::Record::ATOM structs.
    # respects DEFAULT_FIND_PAIRS_OPTS and DEFAULT_H_BOND_OPTS
    # expects that hydrogen bonds are already specified in the PDB file
    # returns an array triplet atom IDs [donor, hydrogen, acceptor]
    # :connections can be passed in (an array of arrays of all unique pairwise
    # connections [by ID])
    def from_pdb(file, opt={})
      opt = DEFAULT_H_BOND_OPTS.merge(opt)

      pairs = find_pairs(file, opt[:select_donor], opt[:select_acceptor], opt)
      p pairs.first

      connection_pairs = Pymol::Connections.from_pdb(file)
      connection_index = Hash.new {|h,k| h[k] = [] }
      connection_pairs.each do |pair|
        connection_index[pair.first] << pair.last
        connection_index[pair.last] << pair.first
      end

      # make an index of the atoms
      pdb = Bio::PDB.new(IO.read(file)) 
      pdb.extend(Bio::PDB::AtomFinder)
      atom_index = []
      pdb.each_atom do |atom|
        atom_index[atom.serial] = atom
      end

      max_angle = opt[:max_angle] || DEFAULT_FIND_PAIRS_OPTS[:max_angle]
      cutoff_in_degress = max_angle

      hbonds = []
      puts "calculating angles and distances" if $VERBOSE
      pairs.each do |don_id, acc_id, don_to_acc_dist|
        donor = atom_index[don_id]
        acceptor = atom_index[acc_id]  
        next if (acceptor.element == 'H' or donor.element == 'H') # check for sloppy queries
        acceptor_xyz = acceptor.xyz
        donor_xyz = donor.xyz
        connection_index[don_id].each do |id|
          hydrogen = atom_index[id]
          next if hydrogen.element != 'H'

          puts "ACCEPT ID: "
          puts acc_id
          p acceptor_xyz
          puts "HYDRO ID: "
          p id
          p hydrogen.xyz
          angle = Bio::PDB::Utils.angle_from_coords([donor_xyz, hydrogen.xyz, acceptor_xyz])
          h_to_acc_dist = Bio::PDB::Utils.distance(hydrogen.xyz, acceptor_xyz)
          puts "DISTANCES: "
          p don_to_acc_dist
          p h_to_acc_dist
           abort 'here'
          # I'm not sure why the angle cutoff is not being respected, but we
          # can enforce it right here since we want the angles anyway
          if (180.0 - Bio::PDB::Utils.rad2deg(angle)) <= cutoff_in_degress
            hbonds << [donor, hydrogen, acceptor, angle, don_to_acc_dist, h_to_acc_dist]
          end
        end
      end
      hbonds
    end

    def list_hb_script(select1, select2)
      %Q{
# modified by JTP from here:
# Dr. Robert L. Campbell
# http://pldserver1.biochem.queensu.ca/~rlc/work/pymol/
# find_pairs is an undocumented method but mode==1 is hydrogen bond finding

from pymol import cmd

def list_hb(selection,cutoff=3.2,angle=55,hb_list_name='hbonds'):
  """
  USAGE

  list_hb selection, [cutoff (default=3.2)], [angle (default=55)], [hb_list_name]

  e.g.
    list_hb 1abc & c. a &! r. hoh, cutoff=3.2, hb_list_name=abc-hbonds
  """
  cutoff=float(cutoff)
  angle=float(angle)
  hb = cmd.find_pairs("((byres "+selection+") #{select1})","((byres "+selection+") #{select2})",mode=1,cutoff=cutoff,angle=angle)
# sort the list for easier reading
  hb.sort(lambda x,y:(cmp(x[0][1],y[0][1])))

  for pairs in hb:
    print "PAIR:",
    for ind in [0,1]:
      cmd.iterate("%s and index %s" % (pairs[ind][0],pairs[ind][1]), 'print "%s/%3s`%s/%s/%s " % (chain,resn,resi,name,index),')
    print "%.2f" % cmd.distance(hb_list_name,"%s and index %s" % (pairs[0][0],pairs[0][1]),"%s and index %s" % (pairs[1][0],pairs[1][1]))

cmd.extend("list_hb",list_hb)
}
    end

    # takes output of hb_script and returns an array of triplets [id1, id2, distance]
    def list_hb_parser(pymol_hb_script_reply, flag=/^PAIR: /)
      # grab each line of output with specified header, then remove the header
      hbond_lines = pymol_hb_script_reply.split("\n").select {|line| line =~ flag }.map {|line| line.sub(flag,'') }

      ids_and_distances = hbond_lines.map do |line|
        # A/THR`325/N/2478  A/ALA`323/O/2468  3.05
        (first, second, dist) = line.split(/\s+/)
        (id1, id2) = [first, second].map {|v| v.split('/').last.to_i }
        [id1, id2, dist.to_f]
      end
    end
  end
end
