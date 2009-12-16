
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
    min_sleep = opt[:sleep] || 1
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
    IO.popen(pymol_cmd, 'w+') do |pipe|
      to_run = pymol_obj.cmds.map {|v| v + "\n" }.join
      pipe.puts to_run
      filesz = -1
      loop do
        sleep(min_sleep)
        if fl = opt[:sleep_til]
          puts "LOOKING FOR #{fl}" if $VERBOSE
          if File.exist?(fl)
            size = File.size(fl)
            break if size == filesz
            filesz = size  
          end
        end
      end
      pipe.close_write
      loop do 
        sleep(min_sleep)
        before_read_size = reply.size
        reply << pipe.read
                else
          break if reply.size == before_read_size
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
