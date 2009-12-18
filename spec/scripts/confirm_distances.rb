#!/usr/bin/ruby

require 'rsruby'
require 'narray'
require 'runarray/more'
require 'gnuplot'

class NArray
  include Runarray::More
  alias_method :avg, :mean
end

if ARGV.size != 2
  puts "theirs mine"
  exit
end
(theirs, mine) = ARGV

their_pairs = IO.readlines(theirs).map do |line|
  pieces = line.chomp.split(/\s+/)
  [pieces.first[3..-1].to_i, pieces.last.to_f]
end

their_index = []
their_pairs.each do |res, dist|
  their_index[res] = dist
end

lines = IO.readlines(mine)
lines.shift

my_pairs = lines.map do |line|
  pieces = line.split(',')
  [pieces[1].to_i, pieces[12].to_f]
end

x = [] ; y = []
my_pairs.each do |i, dist|
  if their_index[i]
    x << dist 
    y << their_index[i]
  end
end

p x
p y

intersection = x.size
my_hbond_count = my_pairs.size
their_hbond_count = their_index.size

set_analysis = [[:jtp, my_hbond_count], [:insight, their_hbond_count], [:intersection, intersection]]
title_string = set_analysis.map {|pair| pair.join('=')}.join(', ')


(rsq, slope, inter) = NArray.to_na(x).rsq_slope_intercept(NArray.to_na(y)).map {|v| "%0.2f" % v }

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.terminal "png"
    plot.output "jtp_vs_insight_surface_distances.png"
    plot.title "2pERK2_Hadded.pdb - #{title_string}"
    plot.xlabel "[JTP] distance from H to surface (Angstrom)"
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



