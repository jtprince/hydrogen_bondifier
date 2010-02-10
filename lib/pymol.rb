require 'tempfile'


class Pymol

  TMP_PYTHON_SCRIPT_FILENAME = "python_script_for_pymol"
  TMP_PYMOL_SCRIPT_FILENAME = "pymol_script"
  TMP_PYMOL_REPLY_FILENAME = "pymol_reply"

  PYMOL_SCRIPT_POSTFIX = '.pml'  # <- very freaking important
  PYTHON_SCRIPT_POSTFIX = '.py'  # <- very freaking important

  attr_accessor :cmds

  def self.run(opt={}, &block)
    self.new.run(opt, &block)
  end

  def initialize
    @cmds = [] 
  end

  def cmd(string)
    @cmds << string
  end

  # you can add your path to pymol to this array if you need to 
  # or with a commandline flag
  PYMOL_EXE_TO_TRY = ['PyMOL.exe', 'pymol']

  ####################################################
  # determine if we have pymol and how to execute it
  ####################################################
  PYMOL_EXE_TO_TRY.unshift(ENV['PYMOL_EXE']) if ENV['PYMOL_EXE']
  to_use = false
  PYMOL_EXE_TO_TRY.each do |name|
    begin
      _cmd = "#{name} -cq"
      if system(_cmd)
        to_use = _cmd
        break
      end
    rescue
    end
  end

  if to_use
    PYMOL_QUIET = to_use
    puts "pymol executable looks good: '#{PYMOL_QUIET}'" if $VERBOSE
  else
    abort "pymol not installed or can't find path, specify with --path-to-pymol" if !to_use
  end

  def run(opt={}, &block)
    puts( "[working in pymol]: " + opt[:msg] + " ...") if (opt[:msg] && $VERBOSE)

    block.call(self)

    cmds_to_run = self.cmds.map

    tmpfiles = []
    if script = opt[:script]
      script_tmpf = Tempfile.new( [TMP_PYTHON_SCRIPT_FILENAME, '.py'], Dir.pwd)
      script_tmpfn = script_tmpf.path
      File.open(script_tmpfn, 'w') {|out| out.print script }
      tmpfiles << script_tmpf
      cmds_to_run.unshift( "run #{script_tmpfn}" )
    end

    to_run = cmds_to_run.map {|v| v + "\n" }.join

    pymol_tmpf = Tempfile.new([TMP_PYMOL_SCRIPT_FILENAME, PYMOL_SCRIPT_POSTFIX], Dir.pwd)
    pymol_tmpfn = pymol_tmpf.path
    File.open(pymol_tmpfn, 'w') {|out| out.print to_run }
    tmpfiles << pymol_tmpf

    # much more suave to open a pipe, but python does not play well with pipes
    # and this is *MUCH* more compatible with windows
    pymol_reply_tmpf = Tempfile.new([TMP_PYMOL_REPLY_FILENAME, '.pmolreply'], Dir.pwd)
    tmpfiles << pymol_reply_tmpf
    pymol_reply_tmpfn = pymol_reply_tmpf.path
    system_cmd = "#{PYMOL_QUIET} #{pymol_tmpfn} > #{File.basename(pymol_reply_tmpfn)}"
    system system_cmd

    reply = IO.read(pymol_reply_tmpfn)
    
    tmpfiles.each {|tmpf| tmpf.close(true) }  # unlinks it too
    self.cmds.clear
    reply
  end

end
