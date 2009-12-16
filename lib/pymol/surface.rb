
class Pymol
  module Surface
    # returns three arrays for the x,y,z coords
    def self.obj_file_to_coords(file)
      coords = []
      IO.foreach(file) do |line|
        if line =~ /^v /
          pieces = line.split(' ')
          pieces.shift  # remove the 'v'
          coords << pieces.map {|v| v.to_f }
        end
      end
      coords
    end

    # returns coordinates
    # http://pymolwiki.org/index.php/Surface#Exporting_Surface.2FMesh_Coordinates_to_File
    def self.from_pdb(file, delete_tmp=true)
      outfile = file.chomp(File.extname(file)) + "_surface.obj"
      Pymol.run(:msg => 'creating surface', :script => HydrogenBondifier::PythonScript.orient_to_pdb_coords) do |pm|
        pm.cmd "load #{file}, mymodel"
        pm.cmd "orient_to_pdb_coords"
        pm.cmd "show surface, mymodel"
        pm.cmd "save #{outfile}"
      end
      coords = self.obj_file_to_coords(outfile)
      File.unlink outfile if delete_tmp
    end
  end
end
