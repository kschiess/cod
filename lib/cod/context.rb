module Cod
  # Channels inside a context know each other and can be looked up by their
  # identifier. 
  #
  class Context
    def initialize
      @pipes = {}
    end
    
    def pipe(name=nil)
      Cod::Channel::Pipe.new(name).
        tap { |channel| register_pipe(channel) }
    end
    
    def beanstalk(url, name=nil)
      Cod::Channel::Beanstalk.new(url, name)
    end
    
    def create_reference(identifier)
      @pipes.fetch(identifier)
    end
    
  private
    def register_pipe(pipe)
      @pipes.store pipe.object_id, pipe
    end
  end
end