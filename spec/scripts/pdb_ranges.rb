require 'bio/db/pdb'

pdb = Bio::PDB.new(IO.read(ARGV.shift))


x = []
y = []
z = []

all = [x,y,z]

pdb.each do |model|
  model.each do |chain|
    chain.each do |residue|
      residue.each do |atom|
        atom.xyz.to_a.zip(all) do |v, ar|
          ar << v
        end
      end
    end
  end
end

maxs = all.map {|v| v.max }
mins = all.map {|v| v.min }

p maxs
p mins

p mins.zip(maxs).map {|mn, mx| mx - mn }
