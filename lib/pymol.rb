
require 'open3'

class Pymol

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
    min_sleep = opt[:sleep_inc] || 1
    puts( "[working in pymol]: " + opt[:msg] + " ...") if (opt[:msg] && $VERBOSE)

    if script = opt[:script]
      scriptname = "python_script_for_pymol.tmp"
      File.unlink(scriptname) if File.exist?(scriptname)
      File.open(scriptname, 'w') {|out| out.print script }
    end
    pymol_cmd = "#{PYMOL_QUIET} -p"
    reply = ""

    puts "ACTUALLY RUNNING:"
    puts IO.read(scriptname) if scriptname

    block.call(self)
    cmds_to_run = self.cmds.map
    cmds_to_run.unshift( "run #{scriptname}" ) if script
    to_run = cmds_to_run.map {|v| v + "\n" }.join
    
    reply = ""

    # I'm not happy about using two completely different IO methods with
    # pymol, but each seems the solution that 'always' works for their
    # problem.

    if til_file = opt[:til_file]
      IO.popen(pymol_cmd, 'w+') do |pipe|
        pipe.puts to_run
        prev_file_size = -1
        loop do
          sleep(min_sleep)
          if File.exist?(til_file)
            size = File.size(til_file)
            break if size == prev_file_size
            prev_file_size = size  
          end
        end
        pipe.close_write
        loop do 
          sleep(min_sleep)
          before_read_size = reply.size
          reply << pipe.read
          break if reply.size == before_read_size
        end
      end
    else
      Open3.popen3(pymol_cmd) do |stdin, stdout, stderr|
        stdin.puts to_run

        reply = ""

        # await input for 0.5 seconds, will return nil and
        # break the loop if there is nothing to read from stdout after 0.5s
        while ready = IO.select([stdout], nil, nil, min_sleep)
          # read until the current pipe buffer is empty
          begin
            reply << stdout.read_nonblock(32768)
          rescue Errno::EAGAIN
            break 
          end while true
        end
      end
    end

    if scriptname
      File.unlink(scriptname) if File.exist?(scriptname)
    end
    self.cmds.clear
    reply
  end

end
