module Cod
  
  # A subprocess that is being run in server mode (think git-server). Use 
  # {Cod}.process to obtain an instance of this. You can then call {#channel} to 
  # obtain a Cod channel to communicate with the $stdio server you've spawned. 
  #
  # @example
  #   process = Cod.process('ls', Cod::LineSerializer.new)
  #   process.wait
  #   loop do
  #     # Will list all entries of the current dir in turn, already chomped.
  #     msg = process.get rescue nil
  #     break unless msg
  #   end
  #
  class Process
    # The pid of the process that was spawned.
    attr_reader :pid 
    
    def initialize(command, serializer=nil)
      @serializer = serializer || SimpleSerializer.new

      run(command)
    end
    
    def run(command)
      @pipe = Cod.bidir_pipe(@serializer)
      
      @pid = ::Process.spawn(command, 
        :in => @pipe.w.r, 
        :out => @pipe.r.w)
    end
    
    def channel
      @pipe
    end
    
    def kill
      ::Process.kill :TERM, @pid
    end
    def terminate
      @pipe.w.close
    end
    
    def wait
      ::Process.wait(@pid)
    rescue Errno::ECHILD
    end
  end
end