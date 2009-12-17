require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'basic tests' do

  before do
    @file = '3IG9.pdb'
    origfile = TESTFILES + '/' + @file
    File.copy origfile, @file
    @pdb = Bio::PDB.new(IO.read(@file))
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'can run commands' do
    newfile = @file + ".HADDED.pdb"
    Pymol.run(:til_file => newfile) do |p|
      p.cmd "load #{@file}, mdl" 
      p.cmd "h_add"
      p.cmd "save #{newfile}"
    end
    ok File.exist?(newfile)
    newfile.size.is 2345
  end
end
