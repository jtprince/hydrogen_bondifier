
class Pymol
  EXCLUDE_WATER_FILTER = " &! resn hoh"
  module HydrogenBonds

    SELECT_O_N_donors = "and (elem n,o and (neighbor hydro))"
    SELECT_O_N_acceptors = "and (elem o or (elem n and not (neighbor hydro)))"
    SELECT_H = "and (elem h and (neighbor o,n))"

    DEFAULT_FIND_PAIRS_ARGS = {:cutoff => 3.2, :angle => 55, :exclude_water => true }

    # returns [id1, id2, distance] for each atom
    def self.find_pairs(file, sel1, sel2, opt={})
      opt = DEFAULT_FIND_PAIRS_ARGS.merge( opt )
      exclude_water_command = opt[:exclude_water] ? EXCLUDE_WATER_FILTER : ""
      hbond_script = HydrogenBondifier::PythonScript.list_hb(sel1, sel2)
      reply = Pymol.run(:msg => "getting hydrogen bonds", :script => hbond_script) do |pm|
        pm.cmd "load #{file}, mymodel"
        pm.cmd "list_hb mymodel#{exclude_water_command}, #{opt[:cutoff]}, #{opt[:angle]}"
      end
      HydrogenBondifier::list_hb_parser(reply)
    end

    # expects that hydrogen bonds are already specified in the PDB file
    # returns an array triplet atom IDs [donor, hydrogen, acceptor]
    def self.from_pdb(file, connection_pairs, sel_don=SELECT_O_N_donors, sel_acc=SELECT_O_N_acceptors, sel_h=SELECT_H, opt={})
      opt = DEFAULT_FIND_PAIRS_ARGS.merge(opt)
      connection_index = Hash.new {|h,k| h[k] = [] }
      connection_pairs.each do |pair|
        connection_index[pair.first] << pair.last
        connection_index[pair.last] << pair.first
      end
      don_acc = find_pairs(file, sel_don, sel_acc, opt)
      h_acc = find_pairs(file, sel_h, sel_acc, opt)
      h_to_don = {}
      h_acc.each do |row|
        (hyd, acc, ha) = row
        h_to_don[[hyd, acc]] = ha
      end
      final = []
      don_acc.each do |row|
        (don, acc, da_dist) = row
        connection_index[don].each do |con_to_donor_id|
          if h_to_don[[con_to_donor_id, acc]]
            final << [don, con_to_donor_id, acc]
          end
        end
      end
      final
    end
  end
end
