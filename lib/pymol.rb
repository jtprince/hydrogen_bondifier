
class Pymol

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
  PYMOL_EXE_TO_TRY.unshift(opt[:path_to_pymol]) if opt[:path_to_pymol]
  to_use = false
  PYMOL_EXE_TO_TRY.each do |name|
    begin
      _cmd = "#{name} -cq"
      if system(_cmd)
        to_use = _cmd
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

  def run(opts={}, &block)
    puts( "[working in pymol]: " + opts[:msg] + " ...") if (opts[:msg] && $VERBOSE)

    cmd_trailer = " -p"
    if python_script = opts[:python_script]
      scriptname = "python_script_for_pymol.tmp"
      File.unlink(scriptname) if File.exist?(scriptname)
      File.open(scriptname, 'w') {|out| out.print python_script }
      cmd_trailer << " -r #{pythong_script}"
    end
    pymol_cmd = "#{PYMOL_QUIET} #{cmd_trailer}"
    reply = ""
    block.call(self)
    IO.popen(pymol_cmd, 'w+') do |pipe|
      to_run = @cmds.map {|v| v + "\n" }.join
      pipe.puts to_run
      loop do 
        sleep(1)
        before_read_size = reply.size
        reply << pipe.read
        break if reply.size == before_read_size
      end
    end
    if scriptname
      File.unlink(scriptname) if File.exist?(scriptname)
    end
    @cmds = []
    reply
  end

end
