
class Pymol
  module Connections
    # returns all connections as pairs of ID's (all uniq)
    def from_pdb(pdb)
      reply = Pymol.run(:msg => 'getting all atom connections', :script => HydrogenBondifier::PythonScript.all_connections) do |pm|
        pm.cmd "load #{pdb}, mymodel"
        pm.cmd "all_connections mymodel"
      end
      HydrogenBondifier::PythonScript.all_connections_parser(reply)
    end
  end
end
