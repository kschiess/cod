module Cod
  class Process
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
    end
  end
end