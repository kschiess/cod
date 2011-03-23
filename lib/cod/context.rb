module Cod
  # Channels inside a context know each other and can be looked up by their
  # identifier. 
  #
  class Context
    def pipe(name=nil)
      Cod::Channel::Pipe.new(name)
    end
    
    def beanstalk(url, name=nil)
      Cod::Channel::Beanstalk.new(url, name)
    end
    
    def create_reference(identifier)
      identifier.obtain_reference(self).dup
    end
  end
end