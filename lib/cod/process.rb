module Cod
  
  # A subprocess that is being run in server mode (think git-server). Use 
  # {Cod}.process to obtain an instance of this. You can then call {#channel} to 
  # obtain a Cod channel to communicate with the $stdio server you've spawned. 
  #
  # @example List the files in a directory
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
    # @return [Number]
    attr_reader :pid 
    
    # Constructs a process object and runs the command. 
    #
    # @see Cod#process
    def initialize(command, serializer=nil)
      @serializer = serializer || SimpleSerializer.new

      run(command)
    end
    
    # @private
    def run(command)
      @pipe = Cod.bidir_pipe(@serializer)
      
      @pid = ::Process.spawn(command, 
        :in => @pipe.w.r, 
        :out => @pipe.r.w)
    end
    
    # Returns the cod channel associated with this process. The channel will
    # have the process' standard output bound to its #get (input), and the
    # process' standard input will be bound to #put (output).
    #
    # Note that when the process exits and all communication has been read from
    # the channel, it will probably raise a Cod::ConnectionLost error. 
    #
    # @example
    #   process = Cod.process('uname', LineSerializer.new)
    #   process.channel.get # => {Darwin,Linux,...}
    # 
    # @return [Cod::Pipe]
    #
    def channel
      @pipe
    end
    
    # Stops the process unilaterally. 
    # 
    # @return [void]
    #
    def kill
      terminate
      ::Process.kill :TERM, @pid
    end
    
    # Asks the process to terminate by closing its stanard input. This normally
    # closes down the process, but no guarantees are made. 
    #
    # @return [void]
    #
    def terminate
      @pipe.w.close
    end
    
    # Waits for the process to terminate and returns its exit value. May
    # return nil, in which case someone else already reaped the process.
    #
    # @return [Number,nil]
    #
    def wait
      ::Process.wait(@pid)
    rescue Errno::ECHILD
    end
  end
end