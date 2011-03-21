module Cod
  # A channel that uses IO.pipe as its transport mechanism. This means that
  # you can only communicate within a single process hierarchy using this, 
  # since the file descriptors are not visible to the outside world. 
  #
  class Channel::Pipe
    # A tuple storing the read and the write end of a IO.pipe. 
    #
    Fds = Struct.new(:r, :w)
    
    attr_reader :fds
    
    # Construct a channel. If you give the channel a name, it can be looked up
    # and used using that name, otherwise the only way to achieve the same
    # thing is either forking (which creates two identical copies) or #dup'ing. 
    # the channel. 
    #
    def initialize(name=nil)
      @fds = Fds.new(*IO.pipe)
      @waiting_messages = []
    end
    
    def put(message)
      close_read
      
      unless fds.w
        direction_error 'Cannot put data to pipe. Already closed that end?'
      end

      buffer = [message.size].pack('l') + message
      fds.w.write(buffer)
    rescue Errno::EPIPE
      direction_error "You should #dup before writing; Looks like no other copy exists currently."
    end
    
    def waiting?
      process_inbound_nonblock
      not @waiting_messages.empty?
    end
    
    def get
      close_write

      return @waiting_messages.shift if waiting?

      loop do
        IO.select([fds.r], nil, nil, 0)
        process_inbound_nonblock
        return @waiting_messages.shift if waiting?
      end
      # NEVER REACHED

    rescue Errno::EPIPE
      direction_error 'Cannot get data from pipe. Already closed that end?'
    end
    
    def close
      fds.w.close if fds.w
      fds.r.close if fds.r
    end

    # Constructs a duplicate of the current channel, with working internal
    # structures. 
    #
    # When you want to do intraprocess-communication, you will need two ends
    # of a channel in the same process. Since writing (or reading) to (from) a
    # channel closes the other end, you will need to make a duplicate of the
    # channel before starting to work with it. 
    #
    def initialize_copy(old)
      old_fds = old.fds

      raise ArgumentError, 
        "Dupping a pipe channel only makes sense if it is still unused." \
          unless old_fds.r && old_fds.w

      @fds = Fds.new(
        old_fds.r.dup, 
        old_fds.w.dup)
    end
    
  private
    def direction_error(msg)
      raise Cod::Channel::DirectionError, msg
    end
  
    def ready?
      ready = IO.select([fds.r], nil, nil, nil)
      ready && ready.first == fds.r
    end
  
    def close_write
      return unless fds.w
      fds.w.close
      fds.w = nil
    end
    
    def close_read
      return unless fds.r
      fds.r.close
      fds.r = nil
    end
  
    # Tries hard to empty the pipe and to store incoming messages in 
    # @waiting_messages.
    #
    def process_inbound_nonblock
      buffer = fds.r.read_nonblock(1024*1024*1024)
    
      while buffer.size > 0
        size = buffer.slice!(0...4).unpack('l').first
        @waiting_messages << buffer.slice!(0...size)
      end
    rescue Errno::EAGAIN
      # Catch and ignore this: fds.r is not ready and read would block.
    end
  end
end