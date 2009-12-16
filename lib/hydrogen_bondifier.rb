
module HydrogenBondifier

  module_function

  def pdb_with_hbonds(pdb_filename, newname=nil)
    pfile = pdb_filename
    newname = pfile.chomp(File.extname(pfile)) + "_plus_h.pdb" unless newname
    Pymol.run(:msg => 'creating pdb with hydrogens') do |pm|
      pm.cmd "load #{file}, mymodel"
      pm.cmd "h_add"
      pm.cmd "save #{newname}"
    end
    newname
  end

  def find_hbonds(file, connection_pairs, opts={})
    Pymol::HydrogenBonds.from_pdb(pdb_with_hbonds, connection_pairs, opts)
  end

end
