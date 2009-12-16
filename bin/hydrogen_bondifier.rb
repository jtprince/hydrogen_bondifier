#!/usr/bin/env ruby

# Previous users of Insight(?) used a (<60deg acute angle) cutoff (>120 obtuse)
# and a 2.85, 2.90, or 3.0 Angstrom cutoff for the hydrogen


# see this on hydrogen bond finding in pymol:
# http://www.mail-archive.com/pymol-users@lists.sourceforge.net/msg06680.html

require 'optparse'
require 'yaml'
require 'narray'
require 'bio/db/pdb'
require 'hydrogen_bondifier'
require 'hydrogen_bondifier/utils'
require 'pymol/surface'
require 'pymol/connections'


ft_postfix = {
  'surface' => '_surface.yml',
  'hbonds' => '_hbond_tmp.yml',
  'plus_h' => '_plus_h.pdb',
  'connections' => '_connections.yml'
}
ft_desc = {
  'surface' => 'surface coordinates',
  'hbonds' => 'hydrogen bonds',
  'plus_h' => 'with hydrogens',
  'connections' => 'connections',
}

opt = {
  :cutoff => 3.2,
  :angle => 60,
  :exclude_water => true
}

output_postfix = "_hbonds.csv"

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.pdb ..."
  op.separator "outputs: <file>#{output_postfix}"
  op.on("-v", "--verbose", "explain what's happening") {|v| $VERBOSE = v }
  op.on("-c", "--cutoff <#{opt[:cutoff]}>", Float, "max distance between donor and acceptor") {|v| opt[:cutoff] = v }
  op.on("-a", "--angle <#{opt[:angle]}>", Float, "max angle") {|v| opt[:angle] = v }
  op.on("-d", "--degrees", "angles in degrees") {|v| opt[:degrees] = v }
  op.on("--no-exclude-water", "leaves water molecules in the model") {|v| opt[:exclude_water] = false }
  op.on("--path-to-pymol", "specify path to pymol exe if not found") {|v| opt[:path_to_pymol] = v }
  op.separator " "
  op.on("--write", "write all output files") {|v| ft_postfix.keys.each {|ft| opt["write_#{ft}".to_sym] = v } }
  ft_postfix.keys.sort.each do |ft|
    op.on("--write-#{ft}", "writes <file>#{ft_postfix[ft]} with #{ft_desc[ft]}") {|v| opt["write_#{ft}".to_sym] = v }
    op.on("--load-#{ft} <#{ft_postfix[ft]}>", "loads file with #{ft_desc[ft]}") {|v| opt["load_#{ft}".to_sym] = v }
  end
end
opts.parse!

def load_or_get(key, opts, as_yaml=true, dont_write=false, &block)
  load_key = "load_#{key}".to_sym
  write_key = "write_#{key}".to_sym
  if lf = opt[load_key]
    if as_yaml ; YAML.load_file(lf)
    else ; lf
    end
  else
    reply = block.call
    if wf = opt[write_key]
      File.open(wf, 'w') {|out| out.print reply.to_yaml } unless dont_write
    end
    reply
  end
end


if ARGV.size == 0
  puts opts
  exit
end

files = ARGV.map
ARGV.clear

files.each do |file|

  ft_desc.each do |st|
    key = "write_#{st}".to_sym
    if opt[key]
      opt[key] = key
    end
  end


  # create filenames for output files
  base = file.chomp(File.extname(file))

  final_output = base + output_postfix

  key = 'plus_h'
  plus_h_file = base + key + '.pdb'
  pdb_file_plus_h = load_or_get('plus_h', opts, false, true) do
    HydrogenBondifier.pdb_with_hbonds(file, plus_h_file)
  end

  base_added = pdb_file_plus_h.chomp(File.extname(pdb_file_plus_h))

  connection_pairs = load_or_get('connections', opts, true) do 
    Pymol::Connections.from_pdb(pdb_file_plus_h)  
  end

  hbonds = load_or_get('hbonds', opts, true) do
    HydrogenBondifier.find_hbonds(pdb_file_plus_h, connection_pairs, opts)
  end

  # http://pymolwiki.org/index.php/Surface#Exporting_Surface.2FMesh_Coordinates_to_File
  surface_coords = load_or_get('surface', opts, true) do
    Pymol::Surface.from_pdb(pdb_file_plus_h)
  end

  sc_sz = surface_coords.size
  (xs, ys, zs) = [nil,nil,nil].map { NArray.float(sc_sz) }
  surface_coords.each do |xyz|
    xs = xyz[0]
    ys = xyz[1]
    zs = xyz[2]
  end

  pdb_obj = Bio::PDB.new(IO.read(pdb_file_plus_h))
  pdb_obj.extend(Bio::PDB::AtomFinder)

  atom_index = []
  pdb_obj.each_atom do |atom|
    atom_index[atom.serial] = atom
  end

  characterized = hbonds.map do |triplet|

    atoms = Array.new(3)
    coords = Array.new(3)
    na_coords = Array.new(3)
    triplet.each_with_index do |id,i|
      atoms[i] = atom_index[id]
      coords[i] = atoms[i].xyz
      na_coords[i] = NArray.to_na(coords[i].to_a)
    end

    # get the distance from hydrogen to surface
    dists_to_surface = Bio::PDB::Utils.distance_to_many(atoms[1].xyz, [xs, ys, zs] )

    angle = Bio::PDB::Utils.angle_from_coords(na_coords)
    angle = Bio::PDB::Utils.rad2deg(angle) if opt[:degrees]
    angle

    (d_to_h_dist, h_to_a_dist, d_to_a_dist) = [[0,1], [1,2], [0,2]].map do |a,b|
      Bio::PDB::Utils.distance(a,b)
    end

    [angle, dists_to_surface.min, d_to_h_dist, h_to_a_dist, d_to_a_dist]
  end

  p characterized

end



  #rows = triplets.zip(angles, distances).map do |triplet, angle, distance_ar|
    ## chain resi element atom_name atom_id
    #id_entries = [triplet.first, triplet.last].map {|a| [a.residue.chain.chain_id, a.residue.id, a.element, a.name, a.serial] }

    #id_entries = id_entries.first.push(triplet[1].name).push(*id_entries.last)

    #id_entries.push( angle, *distance_ar )
  #end

  #id_part = %w(donor acceptor).map do |tp| 
    #%w(chain res element atom_name atom_id).map {|v| [tp, v].join("_") }
  #end
  #id_part = id_part.first.push('hydrogen_name').push(*id_part.last)
  #rows.unshift(id_part.push(*%w(angle h_surf_dist h_accept_dist donor_accept_dist)) )

  #File.open(final_output, 'w') {|out| out.print( rows.map{|row| row.join(',')}.join("\n") << "\n" ) }

  #unless opt[:write_plus_h]
    #File.unlink(pdb_file_plus_h) if File.exist?(pdb_file_plus_h) && (opt[:load_plus_h] != pdb_file_plus_h)
  #end
#end

#[python_hydrogen_bonds_script_name, python_orient_to_pdb_coords_script_name].each do |file|
  #File.unlink(file) if File.exist?(file)
