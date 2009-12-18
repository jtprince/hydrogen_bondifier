class Pymol
  module Orientation

    module_function
    # http://www.mail-archive.com/pymol-users@lists.sourceforge.net/msg06973.html
    def orient_to_pdb_coords_script
      %q{
def orient_to_pdb_coords():
  """
  USAGE

  orient_to_pdb_coords
  """
  cmd.reset()
  cmd.origin(position=[0,0,0])
  cmd.center("origin")
  cmd.move('z',-cmd.get_view()[11])

cmd.extend("orient_to_pdb_coords", orient_to_pdb_coords)
}
    end
  end
end
