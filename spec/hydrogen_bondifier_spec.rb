
describe 'basic tests' do

  before do
    @file = TESTFILES + '/2pERK2_Hadded.pdb'
    @pdb = Bio::PDB.new(IO.read(@file))
  end

  it 'connects hydrogen to its proper atom' do
    @atom.each do | 
    hydro_name_to_connected_name
  end
end
