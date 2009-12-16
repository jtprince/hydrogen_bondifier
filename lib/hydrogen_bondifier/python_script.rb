

module HydrogenBondifier
  module PythonScript

    def self.all_connections
      %Q{
from pymol import cmd

def all_connections(selection):
  """
  USAGE

  all_connections selection

  returns lines: "CONNECTION: id - id"
  """
  stored.xs = []
  cmd.iterate(selection, 'stored.xs.append( index )')
  for i in stored.xs:
    selName = "neighbor%s" % i
    ids = cmd.select(selName, ("%s and neighbor id %s" % (selection, i)))
    base = "CONNECTION: %s - " % i 
    to_print = base + "%s"
    print_string = 'print "' + to_print + '" % index'
    cmd.iterate(selName, print_string )

cmd.extend("all_connections", all_connections)
}
    end

    # returns an array of all pairs of atom IDs with no redundancy
    def self.all_connections_parser(reply_from_all_connections, flag=/^CONNECTION: /)
      pairs = reply_from_all_connections.split("\n").select {|v| v =~ flag }.map do |line|
        line.split(':').last.split(' - ').map {|v| v.to_i }.sort
      end
      pairs.uniq
    end

    def self.list_hb(select1, select2)
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
    def self.list_hb_parser(pymol_hb_script_reply, flag=/^PAIR: /)
      # grab each line of output with specified header, then remove the header
      hbond_lines = pymol_hb_script_reply.split("\n").select {|line| line =~ flag }.map {|line| line.sub(flag,'') }

      ids_and_distances = hbond_lines.map do |line|
        # A/THR`325/N/2478  A/ALA`323/O/2468  3.05
        (first, second, dist) = line.split(/\s+/)
        (id1, id2) = [first, second].map {|v| v.split('/').last.to_i }
        [id1, id2, dist.to_f]
      end
    end


# http://www.mail-archive.com/pymol-users@lists.sourceforge.net/msg06973.html
    def self.orient_to_pdb_coords
      %q{
def orient_to_pdb_coords():
  """
  USAGE

  orient_to_pdb_coords
  """
  cmd.reset()
  cmd.origin(position=[0,0,0])
  cmd.center("origin")
  cmd.move('z',-cmd.get_view()[11])

cmd.extend("orient_to_pdb_coords", orient_to_pdb_coords)
}
    end

  end
end
