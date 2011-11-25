
require 'stringio'

module Cod
  # A cod channel based on IO.pipe. 
  #
  # NOTE: If you embed Cod::Pipe channels into your messages, Cod will insert
  # the object id of that channel into the byte stream that is transmitted. On
  # receiving such an object id (a machine pointer), Cod will try to
  # reconstruct the channel that was at the origin of the id. This can
  # obviously only work if you have such an object in your address space.
  # There are multiple ways to construct such a situation. Say you want to
  # send a pipe channel to one of your (forked) childs: This will work if you
  # create the channel before forking the child, since master and child will
  # share all objects that were available before the fork. 
  #
  class Pipe
    attr_reader :pipe
    attr_reader :serializer
    
    IOPair = Struct.new(:r, :w) do
      # Performs a deep copy of the structure. 
      def initialize_copy(other)
        super
        self.r = other.r.dup if other.r
        self.w = other.w.dup if other.w
      end
      def write(buf)
        close_r
        raise Cod::ReadOnlyChannel unless w
        w.write(buf)
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

    # A few methods that a pipe split must answer to. The split itself is 
    # basically an array instance; these methods add some calling safety and
    # convenience. 
    #
    module SplitMethods
      def read; first; end
      def write; last; end
    end

    def initialize(serializer=nil)
      super
      @serializer = serializer || SimpleSerializer.new
      @pipe = IOPair.new(*IO.pipe)
    end
    
    # Creates a copy of this pipe channel. This performs a shallow #dup except
    # for the file descriptors stored in the pipe, so that a #close affects
    # only one copy. 
    #
    def initialize_copy(other)
      super
      @serializer = other.serializer
      @pipe = other.pipe.dup
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
      [self.dup.readonly, self.dup.writeonly].tap { |split|
        self.close
        
        split.extend(SplitMethods)
      }
    end
    
    # Using #put on a pipe instance will close the other pipe end. Subsequent
    # #get will raise a Cod::InvalidOperation. 
    #
    # Example: 
    #   pipe.put [:a, :message]
    #
    def put(obj)
      raise Cod::ReadOnlyChannel unless can_write?
      
      pipe.write(
        serializer.en(obj))
    end
    
    # Using #get on a pipe instance will close the other pipe end. Subsequent
    # #put will receive a Cod::InvalidOperation.
    #
    # Example: 
    #   pipe.get # => obj
    #
    def get(opts={})
      raise Cod::WriteOnlyChannel unless can_read?
      pipe.close_w
      
      loop do
        ready = Cod.select(nil, self)
        return deserialize_one if ready
      end
    rescue EOFError
      fail "All pipe ends seem to be closed. Reading from this pipe will not "+
        "return any data."
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
      result = Cod.select(timeout, self)
      not result.nil?
    end
    def to_read_fds
      pipe.r
    end
    
    # Returns true if you can read from this pipe. 
    #
    def can_read?
      not pipe.r.nil?
    end
    
    # Returns true if you can write to this pipe. 
    #
    def can_write?
      not pipe.w.nil?
    end

    # ---------------------------------------------------------- serialization
    def _dump(depth)
      object_id.to_s
    end
    def self._load(string)
      ObjectSpace._id2ref(Integer(string))
    end
  private
    def deserialize_one
      # Now deserialize one message from the buffer in io
      serializer.de(pipe.r)
    end
  end
end