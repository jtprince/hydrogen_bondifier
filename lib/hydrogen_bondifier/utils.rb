require 'narray'

module Bio
  class PDB
    module Utils

      # calculates the angle between 2 Narray vecs (in radians)
      def angle_between_vectors(vec1, vec2)
        nil_vec = NArray[0.0, 0.0, 0.0]
        return nil if (vec1 == nil_vec or vec2 == nil_vec)
        (mag_a, mag_b) = [vec1,vec2].map {|vec| Math::sqrt((vec**2).sum) }
        # acos(dotprod / |a||b|)
        Bio::PDB::Utils.acos( (vec1 * vec2).sum.to_f  /  (mag_a * mag_b) )
      end

      def angle_from_coords(coords)
        a = triplet.last - triplet[1]
        b = triplet.first - triplet[1]
        angle_between_vectors(a,b)
      end

      # other is 3 parallel NArray objects with the x, y and z coordinates
      # or a triplet like coord
      def distance_to_many(coord, other)
        # distance may be another narray or an array of vecs
        sq_diffs = []
        (0...(coord.size)).each do |i|
          pos = coord[i]
          oth = other[i]
          sq_diffs << (oth - pos)**2
        end
        NMath.sqrt(sq_diffs.inject {|sum, vec| sum + vec  })
      end
    end
  end
end
