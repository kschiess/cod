module Cod::ObjectIO
  # Writes objects to an IO stream. 
  #
  class Writer    
    def initialize(serializer, pool)
      @serializer = serializer
      @pool = pool
    end
    
    def put(message)
      @pool.accept

      @pool.each do |connection|
        # TODO Errno::EPIPE when the connection closes here.
        connection.write(serialize(message))
      end
    end
    
    def close
      @pool.close
    end
    
  private
    def serialize(message)
      @serializer.serialize(message)
    end
  end
end