require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'fileutils'
require 'pymol/connections'

describe 'pymol connections' do

  before do
    @file = 'little.pdb'
    origfile = TESTFILES + '/' + @file
    FileUtils.copy origfile, @file
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'finds all connections in the molecule' do
    id_pairs = Pymol::Connections.from_pdb(@file)
    id_pairs[0,2].enums [[1, 2], [1, 6]]
    id_pairs[-2,2].enums [[204, 209], [205, 206]]
    id_pairs.size.is 210
  end

end
