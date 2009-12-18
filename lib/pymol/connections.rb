require 'pymol'

class Pymol
  module Connections
    module Script
      module_function

      def all_connections_script
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
      def all_connections_parser(reply_from_all_connections, flag=/^CONNECTION: /)
        pairs = reply_from_all_connections.split("\n").select {|v| v =~ flag }.map do |line|
          line.split(':').last.split(' - ').map {|v| v.to_i }.sort
        end
        pairs.uniq
      end

    end

    module_function

    # returns all connections as pairs of ID's (all uniq)
    def from_pdb(pdb)
      reply = Pymol.run(:msg => 'getting all atom connections', :script => Pymol::Connections::Script.all_connections_script) do |pm|
        pm.cmd "load #{pdb}, mymodel"
        pm.cmd "all_connections mymodel"
      end
      Pymol::Connections::Script.all_connections_parser(reply)
    end
  end
end
