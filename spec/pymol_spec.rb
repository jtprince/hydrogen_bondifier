require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'fileutils'
require 'pymol'

describe 'pymol running basic tests' do

  before do
    @file = 'little.pdb'
    origfile = TESTFILES + '/' + @file
    FileUtils.copy origfile, @file
  end

  after do
    File.unlink @file if File.exist?(@file)
  end

  it 'can run commands and wait for a file to be written' do
    newfile = @file.sub(/\.pdb/i, ".HADDED.pdb")
    reply = Pymol.run do |p|
      p.cmd "load #{@file}, mdl" 
      p.cmd "h_add"
      p.cmd "save #{newfile}"
    end
    ok File.exist?(newfile)
    fs = File.size(newfile)
    ok ((fs == 17014) or (fs == 16805))  # linux / windows filesizes
    File.unlink(newfile) if File.exist?(newfile)
  end

  it 'can run commands and wait for stdout output' do
    reply = Pymol.run do |p|
      p.cmd "load #{@file}, mdl" 
      p.cmd "select mysel, mdl and elem o"
      p.cmd 'iterate mysel, print "GRAB: %s" % index'
    end
    reply.split("\n").select {|line| line =~ /^GRAB: / }.size.is 20
  end

end
