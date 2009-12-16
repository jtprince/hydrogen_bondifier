
from pymol import cmd

def all_connections(selection):
  """
  USAGE

  all_connections selection

  returns lines: "CONNECTION: id id"
  """
  stored.xs = []
  cmd.iterate(selection, 'stored.xs.append( index )')
  outit = open("all_connections.output.tmp", 'w')
  for i in stored.xs:
    selName = "neighbor%s" % i
    ids = cmd.select(selName, ("%s and neighbor id %s" % (selection, i)))
    base = "CONNECTION: %s - " % i 
    to_print = base + "%s"
    print_string = 'outit.write "' + to_print + '" % index'
    cmd.iterate(selName, print_string )

cmd.extend("all_connections", all_connections)

