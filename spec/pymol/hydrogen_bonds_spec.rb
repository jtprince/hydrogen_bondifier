require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'fileutils'
require 'pymol/hydrogen_bonds'

describe 'pymol hydrogen bonds' do

  before do
    @file = 'little.pdb'
    origfile = TESTFILES + '/' + @file
    FileUtils.copy origfile, @file
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'finds hydrogen bonds' do
    triplets = Pymol::HydrogenBonds.from_pdb(@file)
    p triplets.first
    1.is 1
  end

end
