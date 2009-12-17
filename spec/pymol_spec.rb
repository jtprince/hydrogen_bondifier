require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'

require 'pymol'

describe 'basic tests' do

  before do
    @file = '2pERK2_Hadded.pdb'
    origfile = TESTFILES + '/' + @file
    FileUtils.copy origfile, @file
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'can run commands and wait for file to be written' do
    newfile = @file + ".HADDED.pdb"
    reply = Pymol.run(:til_file => newfile, :sleep_inc => 1) do |p|
      p.cmd "load #{@file}, mdl" 
      p.cmd "h_add"
      p.cmd "save #{newfile}"
    end
    ok File.exist?(newfile)
    File.size(newfile).is 468022
  end


  it 'can run commands and wait for stdout output' do
    reply = Pymol.run do |p|
      p.cmd "load #{@file}, mdl" 
      p.cmd "select mysel, mdl and elem o"
      p.cmd 'iterate mysel, print "GRAB: %s" % index'
    end
    reply.split("\n").select {|line| line =~ /^GRAB: / }.size.is 530
  end


end
