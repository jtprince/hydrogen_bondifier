require 'pymol'
require 'pymol/script'

class Pymol
  module Connections
    # returns all connections as pairs of ID's (all uniq)
    def self.from_pdb(pdb)
      reply = Pymol.run(:msg => 'getting all atom connections', :script => Pymol::Script.all_connections) do |pm|
        pm.cmd "load #{pdb}, mymodel"
        pm.cmd "all_connections mymodel"
      end
      Pymol::Script.all_connections_parser(reply)
    end
  end
end
