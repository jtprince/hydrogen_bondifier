require 'gnuplot'

require 'runarray/more'
require 'narray'
require 'rsruby'


class NArray
  include Runarray::More
  alias_method :avg, :mean
end

if ARGV.size != 2
  puts "usage: #{File.basename(__FILE__)} <file>_hbonds.csv <file>_HBOND.out"
  exit
end

(mine, theirs) = ARGV

lines = IO.readlines(mine)
lines.shift

my_angle_dist_by_res_and_name = {}
lines.each do |line|
  pieces = line.split(',')
  key = [pieces[1], pieces[5], pieces[7], pieces[9]]
  p key
  my_angle_dist_by_res_and_name[key] = [pieces[11].to_f, pieces[13].to_f]
end
# ["22", "HE", "42", "OD1"] == ["22", "HE", "42", "OD1"]
#["43", "1HD2", "24", "OG1"]
#
#["48", "1HH1", "25", "O"]
#["48", "2HH2", "25", "O"]
#["48", "2HH2", "39", "OG"]
#
#["48", "HH21", "39", "OG"]



lines = []
get_lines = false
IO.foreach(theirs) do |line|
  if get_lines
    lines << line
  end
  if line =~ /^Donor/
    get_lines = true
  end
end

puts "*******************************************"
puts "SECOND"
puts "*******************************************"

res_to_vals = {}
lines.each do |v| 
  pieces = v.chomp.split(/\s+/)
  key = pieces[0].split(':')[1,2].push(*(pieces[1].split(':')[1,2]))
  ## 1HH1
  ## f

  p key
  # 2 = distance
  # 3 = angle

  res_to_vals[key] = [pieces[3].to_f, pieces[2].to_f]
end
abort 'here'

a_x = []
a_y = []
d_x = []
d_y = []
my_angle_dist_by_res_and_name.each do |id, angle, dist|
  p id
  (o_angle, o_dist) = res_to_vals[id]
  if o_angle && o_dist
    a_x << angle 
    a_y << o_angle 
    d_x << dist
    d_y << o_dist
  end
end

intersection = a_x.size
my_hbond_count = my_angle_dist_by_res_and_name.size
their_hbond_count = res_to_vals.size

a_rsi = NArray.to_na(a_x).rsq_slope_intercept(NArray.to_na(a_y)).map {|v| "%0.2f" % v }
d_rsi = NArray.to_na(d_x).rsq_slope_intercept(NArray.to_na(d_y)).map {|v| "%0.2f" % v }

set_analysis = [[:jtp, my_hbond_count], [:insight, their_hbond_count], [:intersection, intersection]]
title_string = set_analysis.map {|pair| pair.join('=')}.join(', ')

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.terminal "png"
    plot.output "jtp_vs_insight_angles.png"
    plot.title "2pERK2_Hadded.pdb - #{title_string}"
    plot.xlabel "[JTP] donor, H, acceptor angle (degrees)"
    plot.ylabel "[Insight] angle (degrees)"

    plot.data << Gnuplot::DataSet.new( [a_x, a_y] ) do |ds|
      ds.title = "RSQ=#{a_rsi[0]} SLOPE=#{a_rsi[1]} INT=#{a_rsi[2]}"
    end
    plot.data << Gnuplot::DataSet.new( [[0,180], [0,180]] ) do |ds|
      ds.with = "lines"
      ds.title = "perfect"
    end
  end
end

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.terminal "png"
    plot.output "jtp_vs_insight_distances.png"
    plot.title "2pERK2_Hadded.pdb - #{title_string}"
    plot.xlabel "[JTP] distance (Angstrom)"
    plot.ylabel "[Insight] distance (Angstrom)"

    plot.data << Gnuplot::DataSet.new( [d_x, d_y] ) do |ds|
      ds.title = "RSQ=#{d_rsi[0]} SLOPE=#{d_rsi[1]} INT=#{d_rsi[2]}"
    end
    plot.data << Gnuplot::DataSet.new( [[0,7], [0,7]] ) do |ds|
      ds.with = "lines"
      ds.title = "perfect"
    end
  end
end

