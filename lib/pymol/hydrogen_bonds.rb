require 'pymol'
require 'pymol/connections'

require 'bio/db/pdb'
require 'hydrogen_bondifier/utils'

class Pymol
  EXCLUDE_WATER_FILTER = " &! resn hoh"
  module HydrogenBonds

    DEFAULT_FIND_PAIRS_ARGS = {:cutoff => 3.2, :angle => 55, :exclude_water => true }

    module_function

    def pdb_with_hbonds(pdb_filename, newname=nil)
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
      opt = DEFAULT_FIND_PAIRS_ARGS.merge( opt )
      exclude_water_command = opt[:exclude_water] ? EXCLUDE_WATER_FILTER : ""
      hbond_script = Pymol::HydrogenBonds.list_hb_script(sel1, sel2)
      reply = Pymol.run(:msg => "getting hydrogen bonds", :script => hbond_script) do |pm|
        pm.cmd "load #{file}, mymodel"
        pm.cmd "list_hb mymodel#{exclude_water_command}, #{opt[:cutoff]}, #{opt[:angle]}"
      end
      Pymol::HydrogenBonds.list_hb_parser(reply)
    end

    DEFAULT_H_BOND_OPTS = {
      :select_donor => "and (elem n,o and (neighbor hydro))",
      :select_acceptor => "and (elem o or (elem n and not (neighbor hydro)))",
    }

    # respects DEFAULT_FIND_PAIRS_ARGS and DEFAULT_H_BOND_OPTS
    # expects that hydrogen bonds are already specified in the PDB file
    # returns an array triplet atom IDs [donor, hydrogen, acceptor]
    def from_pdb(file, opt={})
      pairs = find_pairs(file, opt[:select_donor], opt[:select_acceptor], opt)

      opt = DEFAULT_H_BOND_OPTS.merge(opt)
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

      cutoff = opt[:cutoff] || DEFAULT_FIND_PAIRS_ARGS[:cutoff]
      cutoff_in_radians = cutoff / 0.0174532925

      hbonds = []
      pairs.each do |don_id, acc_id, don_to_acc_dist|
        acceptor = atom_index[acc_id]  
        next if acceptor.element == 'H'
        acceptor_xyz = acceptor.xyz
        donor = atom_index[don_id]
        puts "NOT RIGHT:#{donor.inspect} " if donor.element != 'N' || donor.element != 'O'
       
        donor_xyz = donor.xyz
        connection_index[don_id].each do |id|
          hydrogen = atom_index[id]
          next if hydrogen.element != 'H'
          angle = Bio::PDB::Utils.angle_from_coords([donor_xyz, hydrogen.xyz, acceptor_xyz])
          h_to_acc_dist = Bio::PDB::Utils.distance(hydrogen.xyz, acceptor_xyz)
          #if (Math::PI - angle) <= cutoff_in_radians
          p angle
          if angle <= cutoff_in_radians
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
