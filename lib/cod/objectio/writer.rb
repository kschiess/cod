module Cod::ObjectIO
  # Writes objects to an IO stream. 
  #
  class Writer    
    def initialize(serializer, io=nil, &block)
      @serializer = serializer
      @io = io
      @reconnect_block = block
    end
    
    def put(message)
      attempt_reconnect
      
      @io.write(serialize(message))
    end
    
    def close
      @io.close
    end
    
  private
    def attempt_reconnect
      if @reconnect_block && !@io
        @io = @reconnect_block[]
      end
      fail "Reconnect failed" unless @io
    end
  
    def serialize(message)
      @serializer.serialize(message)
    end
  end
end