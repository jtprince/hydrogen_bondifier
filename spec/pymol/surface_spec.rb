require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'fileutils'
require 'pymol/surface'

class Object
  def enums_close(other, delta)
    self_ar = []
    self.each do |v|
      self_ar << v
    end
    other_ar = []
    other.each do |v|
      other_ar << v
    end
    self_ar.zip(other_ar) do |a,b|
      if a.is_a? Enumerable
        a.enums_close b, delta
      else
        a.should.be.close b, delta
      end
    end
  end
end

describe 'pymol surface' do

  before do
    @file = 'little.pdb'
    origfile = TESTFILES + '/' + @file
    FileUtils.copy origfile, @file
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'finds surface coordinates' do
    coords = Pymol::Surface.from_pdb(@file)
    first_two = [[9.083281, 60.507313, 9.422514], [9.540758, 60.98122, 9.483328]]
    last_two = [[7.323, 47.034184, 6.684179], [5.81, 47.229004, 6.411]]
    coords[0,2].enums_close first_two, 0.0001
    coords[-2,2].enums_close last_two, 0.0001
    coords.size.is 9684
  end

end
