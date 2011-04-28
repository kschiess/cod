module Cod
  # This is mostly documentation: Use it as a template for new channels.
  class Channel::Abstract < Channel::Base
    def initialize(destination)
      not_implemented
    end
    
    def initialize_copy(from)
      not_implemented
    end
    
    def put(message)
      not_implemented
    end
    
    def get(opts={})
      not_implemented
    end
    
    def waiting?
      not_implemented
    end
    
    def close
      not_implemented
    end
    
    def identifier
      not_implemented
    end
  end
end