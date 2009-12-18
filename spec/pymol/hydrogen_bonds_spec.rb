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

    answers_but_atoms_as_ids = [[75, 82, 125, 2.70110007356142, 2.87, 1.9000997342245],
      [122, 131, 78, 2.65823167164358, 2.94, 1.98408492761777],
      [155, 166, 46, 2.77786431401053, 2.89, 1.90544535476618],
      [187, 194, 158, 2.19624439858352, 2.86, 2.13271728084151]]

    triplets.zip(answers_but_atoms_as_ids) do |row1, row2|
      row1[0,3] = row1[0,3].map(&:serial)
      row1.zip(row2) do |v1, v2| 
        if v1.is_a? Integer
          v1.is v2
        else
          v1.should.be.close v2, 0.00001
        end
      end
    end
  end

end
