
# http://www.mail-archive.com/pymol-users@lists.sourceforge.net/msg06211.html

from pymol import cmd

def print_hb(selection):
  hb = cmd.find_pairs("((byres "+selection+") and n;n)","((byres "+selection+") and n;o)",mode=1,cutoff=3.7,angle=55)

  pair1_list = []
  pair2_list = []
  dist_list = []
  for pairs in hb:
    cmd.iterate("%s and ID %s" % (pairs[0][0],pairs[0][1]), 'print "%s/%3s`%s/%s " % (chain,resn,resi,name),')
    cmd.iterate("%s and ID %s" % (pairs[1][0],pairs[1][1]), 'print "%s/%3s`%s/%s " % (chain,resn,resi,name),')
    print "%.2f" % cmd.dist("%s and ID %s" % (pairs[0][0],pairs[0][1]),"%s and ID %s" % (pairs[1][0],pairs[1][1]))

cmd.extend("print_hb",print_hb)

