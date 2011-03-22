module Cod
  # A channel that uses IO.pipe as its transport mechanism. This means that
  # you can only communicate within a single process hierarchy using this, 
  # since the file descriptors are not visible to the outside world. 
  #
  class Channel::Pipe < Channel::Base
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
    
    # Writes a Ruby object (the 'message') to the channel. This object will 
    # be queued in the channel and become available for #get in a FIFO manner.
    #
    # Issuing a #put also closes the channel instance for subsequent #get's. 
    #
    # Example: 
    #   chan.put 'test'
    #   chan.put true
    #   chan.put :symbol
    #
    def put(message)
      close_read
      
      unless fds.w
        direction_error 'Cannot put data to pipe. Already closed that end?'
      end
            
      buffer = transport_pack(message)
      fds.w.write(buffer)
    rescue Errno::EPIPE
      direction_error "You should #dup before writing; Looks like no other copy exists currently."
    end
    
    # Returns true if there are messages waiting in the channel. 
    #
    def waiting?
      process_inbound_nonblock
      queued?
    rescue Cod::Channel::CommunicationError
      # Gets raised whenever communication fails permanently. This means that
      # we probably wont be able to return any more messages. The only messages
      # remaining in such a situation would be those queued.
      return queued?
    end
    
    def get
      close_write
      
      return @waiting_messages.shift if queued?

      loop do
        IO.select([fds.r], nil, [fds.r], 1)
        process_inbound_nonblock
        return @waiting_messages.shift if queued?
      end
      # NEVER REACHED

    rescue Errno::EPIPE
      direction_error 'Cannot get data from pipe. Already closed that end?'
    end
    
    def close
      close_write
      close_read
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
    def communication_error(msg)
      raise Cod::Channel::CommunicationError, msg
    end
  
    # Turns the object into a buffer (simple transport layer that prefixes a
    # size)
    #
    def transport_pack(message)
      serialized = serialize(message)
      buffer = [serialized.size].pack('l') + serialized
    end
    
    # Slices one message from the front of buffer
    #
    def transport_unpack(buffer)
      size = buffer.slice!(0...4).unpack('l').first
      serialized = buffer.slice!(0...size)
      deserialize(serialized)
    end
  
    def queued?
      not @waiting_messages.empty?
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
        @waiting_messages << transport_unpack(buffer)
      end
    rescue EOFError
      # We've just hit end of file in the pipe. That means that all write 
      # ends have been closed. 
      communication_error "All write ends for this pipe have been closed. "+
        "Further #get's would block forever." \
        unless queued?
    rescue Errno::EAGAIN
      # Catch and ignore this: fds.r is not ready and read would block.
    end
  end
end