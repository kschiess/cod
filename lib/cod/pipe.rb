
require 'stringio'

module Cod
  # A cod channel based on IO.pipe. 
  class Pipe
    attr_reader :pipe
    attr_reader :serializer
    
    IOPair = Struct.new(:r, :w) do
      # Performs a deep copy of the structure. 
      def initialize_copy(other)
        super
        self.r = other.r.dup
        self.w = other.w.dup
      end
      def write(buf)
        close_r
        raise Cod::ReadOnlyChannel unless w
        w.write(buf)
      end
      def read_nonblock(size, buffer)
        close_w
        raise Cod::WriteOnlyChannel unless r
        r.read_nonblock(size, buffer)
      end
      def close
        close_r
        close_w
      end
      def close_r
        r.close if r
        self.r = nil
      end
      def close_w
        w.close if w
        self.w = nil
      end
    end

    def initialize(serializer=nil)
      super
      @serializer = serializer || SimpleSerializer.new
      @pipe = IOPair.new(*IO.pipe)
      buffer_init
    end
    
    # Creates a copy of this pipe channel. This performs a shallow #dup except
    # for the file descriptors stored in the pipe, so that a #close affects
    # only one copy. 
    #
    def initialize_copy(other)
      super
      @serializer = other.serializer
      @pipe = other.pipe.dup
      buffer_init
    end
    
    # Makes this pipe readonly. Calls to #put will error out. This closes the
    # write end permanently and provokes end of file on the read end once all
    # processes that posses a link to the write end do so. 
    # 
    # Returns self so that you can write for example: 
    #   read_end = pipe.dup.readonly
    #
    def readonly
      pipe.close_w
      self
    end
    
    # Makes this pipe writeonly. Calls to #get will error out. See #readonly. 
    #
    # Returns self so that you can write for example: 
    #   write_end = pipe.dup.writeonly
    #
    def writeonly
      pipe.close_r
      self
    end
    
    # Actively splits this pipe into two ends, a read end and a write end. The
    # original pipe is closed, leaving only the two ends to work with. The 
    # read end can only be read from (#get) and the write end can only be 
    # written to (#put).
    #
    def split
      [self.dup.readonly, self.dup.writeonly].tap {
        self.close
      }
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

    # Returns if this pipe is ready for reading. 
    #
    def select(timeout=nil)
      result = Cod.select(timeout, this_channel: self)
      result.has_key?(:this_channel)
    end
    def to_read_fds
      pipe.r
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
          io.write(@buffer); io.pos=0 }
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
    def buffer_init
      @buffer = String.new
      @remaining = nil
    end
  end
end