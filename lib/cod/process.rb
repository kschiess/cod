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
        :in => @pipe.w.pipe.r, 
        :out => @pipe.r.pipe.w)
    end
    
    def channel
      @pipe
    end
  end
end