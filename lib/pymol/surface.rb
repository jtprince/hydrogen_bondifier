
class Pymol
  module Surface
    # returns three arrays for the x,y,z coords
    def self.obj_file_to_coords(file)
      p file
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
      puts "FILE: #{file} in pdb"
      puts "EXIst: "
      puts File.exist?(file).to_s

      outfile = file.chomp(File.extname(file)) + "_surface.obj"
      Pymol.run(:msg => 'creating surface', :script => Pymol::Script.orient_to_pdb_coords, :sleep_til => outfile) do |pm|
        pm.cmd "load #{file}, mymodel"
        pm.cmd "orient_to_pdb_coords"
        pm.cmd "show surface, mymodel"
        pm.cmd "save #{outfile}"
      end
      p outfile
      puts File.exist?(outfile).to_s
      
      coords = self.obj_file_to_coords(outfile)
      p coords
      File.unlink outfile if delete_tmp
      coords
    end
  end
end
