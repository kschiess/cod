
require 'stringio'

module Cod
  # A cod channel based on IO.pipe. 
  class Pipe
    attr_reader :pipe
    attr_reader :serializer
    
    IOPair = Struct.new(:r, :w) do
      def write(buf)
        w.write(buf)
      end
      def read_nonblock(size, buffer)
        r.read_nonblock(size, buffer)
      end
      def close
        r.close if r
        self.r = nil
        w.close if w
        self.w = nil
      end
    end

    def initialize(serializer=nil)
      @serializer = serializer || SimpleSerializer.new
      @pipe = IOPair.new(*IO.pipe)
      @buffer = String.new
      @remaining = nil
    end
    
    # Actively splits this pipe into two ends, a read end and a write end. The
    # original pipe is closed, leaving only the two ends to work with. The 
    # read end can only be read from (#get) and the write end can only be 
    # written to (#put).
    #
    def split
      [self, self]# TODO
    end
    
    # Writes a message object to the pipe. You can specify a custom object
    # serializer (including a string passthrough if that is what you want)
    # when constructing the pipe. 
    #
    # Using #put on a pipe instance will close the other pipe end. Subsequent
    # #get will raise a Cod::InvalidOperation. 
    #
    # Example: 
    #   pipe.put [:a, :message]
    #
    def put(obj)
      pipe.write(
        serializer.en(obj))
    end
    
    # Reads a message object from the pipe. 
    #
    # Using #get on a pipe instance will close the other pipe end. Subsequent
    # #put will receive a Cod::InvalidOperation.
    #
    # Allowed options: 
    #   :timeout :: time to wait for a message to arrive, raises Cod::Timeout
    #
    # Example: 
    #   pipe.get # => obj
    #
    def get(opts={})
      # TODO :timeout
      pipe.read_nonblock(1024**2, @buffer)
      
      deserialize_one
    end
    
    # Closes the pipe completely. All active ends are closed. Note that you
    # can call this function on a closed pipe without getting an error raised.
    #
    def close
      pipe.close
    end

    def _dump(depth)
      object_id.to_s
    end
    def self._load(string)
      ObjectSpace._id2ref(Integer(string))
    end
  private
    def deserialize_one
      # Assumes that buffer contains the just read bytes and @remaining
      # contains what we haven't parsed yet.
      # So we need to concat @buffer to @remaining and construct an IO 
      # from that: 
      io = if @remaining
        StringIO.new(@remaining).tap { |io|
          io.write(@buffer) }
      else
        StringIO.new(@buffer)
      end
      
      # Now deserialize one message from the buffer in io
      serializer.de(io).tap {
        # Is there something left to consume in io? If yes, store that
        # buffer in @remaining. 
        @remaining = io.string
      }
    end
  end
end