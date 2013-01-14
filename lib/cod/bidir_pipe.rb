module Cod
  
  # A bidirectional pipe, also called a socket pair. 
  #
  class BidirPipe < Channel
    
    # Serializer to use for messages on this transport. 
    attr_reader :serializer
    
    # This process' end of the pipe, can be used for both reading and writing. 
    attr_reader :socket
    
    # The other side of the pipe. 
    attr_reader :other
    
    def initialize(serializer=nil)
      @serializer = serializer || SimpleSerializer.new
      @socket, @other = UNIXSocket.pair
    end
    
    def put(obj)
      socket.write(
        serializer.en(obj))
    end
    
    def get
      serializer.de(socket)
    rescue EOFError, IOError
      raise Cod::ConnectionLost, 
        "All pipe ends seem to be closed. Reading from this pipe will not "+
        "return any data."
    end
    
    def close
      socket.close; other.close
    rescue IOError
      # One code path through Cod::Process will close other prematurely. This
      # is to avoid an error. 
    end
    
    # Swaps the end of this pipe around. 
    #
    def swap!
      @socket, @other = @other, @socket
    end

    # @private
    #
    def to_read_fds
      [socket]
    end
  end
end