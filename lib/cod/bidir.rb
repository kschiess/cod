module Cod
  
  # A bidirectional pipe, also called a socket pair. 
  #
  class Bidir < Channel
    
    # Serializer to use for messages on this transport. 
    attr_reader :serializer
    
    # This process' end of the pipe, can be used for both reading and writing. 
    attr_reader :socket
    
    # The other side of the pipe. 
    attr_reader :other
    
    # Path of the socket (.named), if based on a file system FIFO.
    attr_reader :path
    
    def self.named(name, serializer=nil)
      new(serializer || SimpleSerializer.new, 
        name, 
        UNIXSocket.new(name), nil)
    end
    def self.pair(serializer=nil)
      new(serializer || SimpleSerializer.new, 
        nil, 
        *UNIXSocket.pair)
    end
    
    # Initializes a Bidir channel given two or alternatively one end of a 
    # bidirectional pipe. (socketpair)
    # 
    #   socket ---- other
    #
    def initialize(serializer, path, socket, other)
      @serializer = serializer
      @socket, @other = socket, other
      @path = path
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
      socket.close; 
      other.close if other
    rescue IOError
      # One code path through Cod::Process will close other prematurely. This
      # is to avoid an error. 
    end
    
    # Swaps the end of this pipe around. 
    #
    def swap!
      @socket, @other = @other, @socket
    end
    
    # ---------------------------------------------------------- serialization 
    
    # A small structure that is constructed for a serialized tcp client on 
    # the other end (the deserializing end). What the deserializing code does
    # with this is his problem. 
    #
    # @private
    #
    OtherEnd = Struct.new(:path) # :nodoc:

    def _dump(level) # :nodoc:
      Marshal.dump(path)
    end
    def self._load(params) # :nodoc:
      # Instead of a tcp client (no way to construct one at this point), we'll
      # insert a kind of marker in the object stream that will be replaced 
      # with a valid client later on. (hopefully)
      OtherEnd.new(Marshal.load(params))
    end

    # @private
    #
    def to_read_fds
      [socket]
    end
  end
end