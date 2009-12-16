lines = nil
IO.foreach(ARGV.shift) do |line|
  lines.push(line) if lines
  if line =~ /^Donor/
    lines = []
  end
end

p (180.0 - lines.map {|line| line.chomp.split(/\s+/)[3].to_f }.select {|v| v > 0.0 }.min)
