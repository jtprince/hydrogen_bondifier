
require 'open3'

class Pymol

  attr_accessor :cmds

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

  def self.run(opt={}, &block)
    min_sleep = opt[:sleep_inc] || 1
    pymol_obj = self.new
    puts( "[working in pymol]: " + opt[:msg] + " ...") if (opt[:msg] && $VERBOSE)

    cmd_trailer = " -p"
    if python_script = opt[:python_script]
      scriptname = "python_script_for_pymol.tmp"
      File.unlink(scriptname) if File.exist?(scriptname)
      File.open(scriptname, 'w') {|out| out.print python_script }
      cmd_trailer << " -r #{pythong_script}"
    end
    pymol_cmd = "#{PYMOL_QUIET} #{cmd_trailer}"
    reply = ""
    
    block.call(pymol_obj)
    to_run = pymol_obj.cmds.map {|v| v + "\n" }.join

    reply = ""
    Open3.popen3(pymol_cmd) do |stdin, stdout, stderr|
      stdin.puts to_run

      reply = ""

      if fl = opt[:til_file]
        loop do
          sleep(min_sleep)
          reply << stdout.read(4096)
          break if File.exist?(fl)
        end
      else
        # await input for 0.5 seconds, will return nil and
        # break the loop if there is nothing to read from stdout after 0.5s
        while ready = IO.select([stdout], nil, nil, min_sleep)
          # read until the current pipe buffer is empty
          begin
            reply << stdout.read_nonblock(4096)
          rescue Errno::EAGAIN
            break unless opt[:til_file]
          end while true
        end
      end
    end

    if scriptname
      File.unlink(scriptname) if File.exist?(scriptname)
    end
    pymol_obj.cmds.clear
    reply
  end

end
