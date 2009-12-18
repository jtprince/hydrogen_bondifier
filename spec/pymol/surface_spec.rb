require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'fileutils'
require 'pymol/surface'

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
    coords[0,2].enums first_two
    coords[-2,2].enums last_two
    coords.size.is 9684
  end

end
