
# list_hb <selection>, cutoff=3.2 (default)

# exclude waters first:
# list_hb 1xnb &! r. hoh, cutoff=3.2

# from: ./pymol/trunk/pymol/layer3/Selector.c
#
#  if(mode == 1) {
#    angle_cutoff = (float) cos(PI * h_angle / 180.8);
#  }
#             ##   cos(PI * 55 / 180.8)  => 0.577  # just converts to radians and takes the cosine
#             ##   so, they take the cosine of the angle as the "angle_cutoff"

# if(mode == 1) {   /* coarse hydrogen bonding assessment */
#             ##   so, mode 1 is hydrogen bonding finding.
#                flag = false;
#                if(ObjectMoleculeGetAvgHBondVector(obj1, at1, state1, v1, NULL) > 0.3)
#                  if(dot_product3f(v1, dir) < -angle_cutoff)
#                    flag = true;
#                if(ObjectMoleculeGetAvgHBondVector(obj2, at2, state2, v2, NULL) > 0.3)
#                  if(dot_product3f(v2, dir) > angle_cutoff)
#                    flag = true;

from pymol import cmd

def list_hb(selection,cutoff=3.2,angle=55,hb_list_name='hbonds'):
  """
  USAGE

  list_hb selection, [cutoff (default=3.2)], [angle (default=55)], [hb_list_name]
  
  e.g.
    list_hb 1abc & c. a &! r. hoh, cutoff=3.2, hb_list_name=abc-hbonds
  """
  cutoff=float(cutoff)
  angle=float(angle)
  hb = cmd.find_pairs("((byres "+selection+") and n;n)","((byres "+selection+") and n;o)",mode=1,cutoff=cutoff,angle=angle)
# sort the list for easier reading
  hb.sort(lambda x,y:(cmp(x[0][1],y[0][1])))

  for pairs in hb:
    for ind in [0,1]:
      cmd.iterate("%s and index %s" % (pairs[ind][0],pairs[ind][1]), 'print "%s/%3s`%s/%s/%s " % (chain,resn,resi,name,index),')
    print "%.2f" % cmd.distance(hb_list_name,"%s and index %s" % (pairs[0][0],pairs[0][1]),"%s and index %s" % (pairs[1][0],pairs[1][1]))

cmd.extend("list_hb",list_hb)
