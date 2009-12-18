#!/usr/bin/env ruby

# Previous users of Insight(?) used a (<60deg acute angle) cutoff (>120 obtuse)
# and a 2.85, 2.90, or 3.0 Angstrom cutoff for the hydrogen

# see this on hydrogen bond finding in pymol:
# http://www.mail-archive.com/pymol-users@lists.sourceforge.net/msg06680.html

require 'yaml'
require 'narray'
require 'optparse'
require 'bio/db/pdb'
require 'pymol/surface'
require 'pymol/connections'
require 'hydrogen_bondifier'
require 'hydrogen_bondifier/utils'

def putsv(*args)
  puts(*args) if $VERBOSE
end

opt = {
  :max_dist => 3.2,
  :max_angle => 60,
  :exclude_water => true,
  :add_hydrogen => true,
  :delim => ','
}

$VERBOSE = true

output_postfix = "_hbonds.csv"

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.pdb ..."
  op.separator "outputs: <file>#{output_postfix}"
  op.separator " "
  op.on("-d", "--max-distance <#{opt[:max_dist]}>", Float, "max distance between donor and acceptor") {|v| opt[:max_dist] = v }
  op.on("-a", "--max-angle <#{opt[:max_angle]}>", Float, "max angle in degrees") {|v| opt[:max_angle] = v }
  op.on("--radians", "output angles in radians") {|v| opt[:radians] = v }
  op.on("--no-exclude-water", "leaves water molecules in the model") {|v| opt[:exclude_water] = false }
  op.on("--no-add-hydrogen", "can use if pdb contains all hydrogens") {|v| opt[:add_hydrogen] = false }
  op.on("-q", "--quiet", "no unnecessary output") {|v| $VERBOSE = false }
  op.separator " "
  op.separator "    * if pymol executable cannot be found, you can specify it as the value of the" 
  op.separator "      environmental variable 'PYMOL_EXE'"
  op.separator "    * pdb file should be in your working directory (and directory writeable)"
  op.separator "    * in output: D=donor, H=hydrogen, A=acceptor"
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

files = ARGV.map
ARGV.clear

categories = %w(D_res_id D_res D_name D_id H_id A_res_id A_res A_name A_id angle D_A_dist H_A_dist H_dist_to_surf)

files.each do |file|

  # create filenames for output files
  base = file.chomp(File.extname(file))

  pdb_with_hydrogens = 
    if opt[:add_hydrogen]
      pdb_plus_h_added = base + '_Hadded.pdb'
      putsv "writing to: #{pdb_plus_h_added}"
      Pymol::HydrogenBonds.pdb_with_hydrogens(file, pdb_plus_h_added)
    else
      file
    end

  base_h_added = pdb_plus_h_added.chomp(File.extname(pdb_plus_h_added))

  hbond_arrays = Pymol::HydrogenBonds.from_pdb(pdb_with_hydrogens, opt)

  # http://pymolwiki.org/index.php/Surface#Exporting_Surface.2FMesh_Coordinates_to_File
  surface_coords = Pymol::Surface.from_pdb(pdb_with_hydrogens)

  sc_sz = surface_coords.size
  (xs, ys, zs) = [nil,nil,nil].map { NArray.float(sc_sz) }
  surface_coords.each_with_index do |xyz, i|
    xs[i] = xyz[0]
    ys[i] = xyz[1]
    zs[i] = xyz[2]
  end

  # get the distance from hydrogen to surface
  # 0 => donor
  # 1 => hydrogen
  # 2 => acceptor
  which_atom = 1

  putsv "calculating distances to surface ..."
  characterized = hbond_arrays.map do |data|
    coords = Array.new(3)
    na_coords = Array.new(3)
    data[0,3].each_with_index do |atom,i|
      coords[i] = atom.xyz
      na_coords[i] = NArray.to_na(coords[i].to_a)
    end

    dists_to_surface = Bio::PDB::Utils.distance_to_many(coords[which_atom], [xs, ys, zs] )

    data[3] = Bio::PDB::Utils.rad2deg(data[3]) unless opt[:radians]
    (don, acc) = [data[0], data[2]].map {|at| [at.residue.id, at.resName, at.name, at.serial] }
    id_part = don.push(data[1].serial).push(*acc)
    id_part.push(*data[3,3]).push(dists_to_surface)
  end

  final_output = base_h_added + output_postfix
  File.open(final_output, 'w') do |out|
    categories.join(opt[:delim])
    characterized.each do |array|
      out.puts array.join(opt[:delim])
    end
  end
end

