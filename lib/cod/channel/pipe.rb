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
      buffer = [message.size].pack('l') + message
      fds.w.write(buffer)
    end
    
    def waiting?
      process_inbound_nonblock
      not @waiting_messages.empty?
    end
    
    def get
      return @waiting_messages.shift if waiting?

      loop do
        IO.select([fds.r], nil, nil, 0)
        process_inbound_nonblock
        return @waiting_messages.shift if waiting?
      end
      
      # NEVER REACHED
    end
    
    def close
      fds.w.close
      fds.r.close
    end
    
  private
    def ready?
      ready = IO.select([fds.r], nil, nil, nil)
      ready && ready.first == fds.r
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