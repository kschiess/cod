
module Cod
  class Channel::Base
    def put(message)
      not_implemented
    end
    
    def get
      not_implemented
    end
    
    def waiting?
      not_implemented
    end
    
    def close
      not_implemented
    end
  private
    def serialize(message)
      Marshal.dump(message)
    end
    
    def deserialize(buffer)
      Marshal.load(buffer)
    end
  
    def not_implemented
      raise NotImplementedError, 
        "You called a method in Cod::Channel::Base. Missing implementation in "+
        "the subclass!"
    end
  end
end