
x = []
y = []
z = []
all = [x,y,z]

IO.foreach(ARGV.shift) do |line|
  if line =~ /^v\s+/
    (_, *coords) = line.chomp.split(/\s+/)
    coords.zip(all) do |coord, ar|
      ar << coord.to_f
    end
  end
end

mins = all.map {|ar| ar.min }
maxs = all.map {|ar| ar.max }

p mins
p maxs

p mins.zip(maxs).map {|mn, mx| mx - mn }
