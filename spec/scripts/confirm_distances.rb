#!/usr/bin/ruby -s

require 'rsruby'
require 'narray'
require 'runarray/more'
require 'gnuplot'



class NArray
  include Runarray::More
  alias_method :avg, :mean
end

def pairs_from_their_format(file)
  their_pairs = IO.readlines(file).map do |line|
    pieces = line.chomp.split(/\s+/)
    [pieces.first[3..-1].to_i, pieces.last.to_f]
  end
end

if ARGV.size != 3
  puts "[-s] theirs mine <from_what>"
  exit
end
(theirs, mine, keywords) = ARGV


if $s   # mine is same format as theirs!
  (their_pairs, my_pairs) = [theirs, mine].map {|f| pairs_from_their_format f }
  their_index = []
  their_pairs.each do |res, dist|
    their_index[res] = dist
  end
else
  their_pairs = pairs_from_their_format(theirs)

  lines = IO.readlines(mine)
  lines.shift

  my_pairs = lines.map do |line|
    pieces = line.split(',')
    [pieces[4].to_i, pieces[12].to_f]
  end
end

x = [] ; y = []
my_pairs.each do |i, dist|
  if their_index[i]
    x << dist 
    y << their_index[i]
  end
end

intersection = x.size
my_hbond_count = my_pairs.size
their_hbond_count = their_index.size

set_analysis = [[:jtp, my_hbond_count], [:insight, their_hbond_count], [:intersection, intersection]]
title_string = set_analysis.map {|pair| pair.join('=')}.join(', ')


(rsq, slope, inter) = NArray.to_na(x).rsq_slope_intercept(NArray.to_na(y)).map {|v| "%0.2f" % v }

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.terminal "png"
    plot.output "jtp_vs_insight_surface_distances_#{keywords.gsub(/\s+/,'_')}.png"
    plot.title "2pERK2_Hadded.pdb - #{title_string}"
    plot.xlabel "[JTP] distance from #{keywords} to surface (Angstrom)"
    plot.ylabel "[Insight] distance from residue to surface (Angstrom)"
    plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
      ds.title = "RSQ=#{rsq} SLOPE=#{slope} INT=#{inter}"
    end
    plot.data << Gnuplot::DataSet.new( [[1,7], [1,7]] ) do |ds|
      ds.with = "lines"
      ds.title = "perfect"
    end
  end
end



