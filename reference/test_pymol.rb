
require 'open3'

cmd = 'pymol -cq -p'

output = nil
IO.popen("pymol -cq -p", 'w+') do |pipe|
  pipe.puts "load 2pERK2_Hadded.pdb, mymodel\n"
  pipe.puts "run all_connections.py"
  pipe.puts "all_connections mymodel"
  pipe.puts "quit"

  IO.select([pipe]) # you shouldn't need to uncomment this...

  output = pipe.read
end 
p output


#my_string = ""
#Open3.popen3(cmd) do |si, so, se|
  #si.puts "run all_connections.py\n"
  #si.puts "load 2pERK2_Hadded.pdb, mdl\n"
  ##si.puts "show surface, mdl\n"
  #si.puts "all_connections mdl\n"
  #si.puts "print \"DONE\""
  #stringsz = -1

  #forstdout = Thread.new do
    #Thread.current['lines'] = ""
    #loop do
      #Thread.current['lines'] << so.read(2024)
    #end
  #end
  #past_size = -1
  #loop do
    #sleep(0.7)
    #csize = forstdout['lines'].size
    #break if csize == past_size
    #past_size = csize
  #end
  #my_string = forstdout['lines']
  #forstdout.kill
  #si.close
#end
#p my_string.size




=begin
IO.popen(cmd, 'w') do |pipe|
  pipe.puts "run all_connections.py\n"
  pipe.puts "load 2pERK2_Hadded.pdb, mdl\n"
  #pipe.puts "show surface, mdl\n"
  pipe.puts "all_connections mdl\n"
  pipe.puts "quit\n"
  can_do = pipe.fsync
  puts can_do
  pipe.close_write
  puts pipe.read
end
=end




cmd = 'pymol -cq -p'

my_string = ""
Open3.popen3(cmd) do |si, so, se|
  si.puts "run all_connections.py\n"
  si.puts "load 2pERK2_Hadded.pdb, mdl\n"
  si.puts "all_connections mdl\n"
  loop do
    if File.exist?("all_connections.output.tmp")
      break
    end
  end
  si.close
end
p my_string.size




