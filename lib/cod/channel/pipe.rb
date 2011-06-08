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
    
    def initialize(name=nil)
      @fds = Fds.new(*IO.pipe)
      
      init_in_and_out
    end

    def initialize_copy(old)
      old_fds = old.fds

      raise ArgumentError, 
        "Dupping a pipe channel only makes sense if it is still unused." \
          unless old_fds.r && old_fds.w

      @fds = Fds.new(
        old_fds.r.dup, 
        old_fds.w.dup)
      
      init_in_and_out
    end
    
    def put(message)
      close_read
      
      unless fds.w
        direction_error 'Cannot put data to pipe. Already closed that end?'
      end
      
      @out.put(message)
    rescue Errno::EPIPE
      direction_error "You should #dup before writing; Looks like no other copy exists currently."
    end
    
    def waiting?
      @in.waiting?
    rescue EOFError
      # We've just hit end of file in the pipe. That means that all write 
      # ends have been closed. 
      @in.queued?
    end
    
    def get(opts={})
      close_write
      
      @in.get(opts)

    rescue EOFError
      # We've just hit end of file in the pipe. That means that all write 
      # ends have been closed. 
      communication_error "All write ends for this pipe have been closed. "+
        "Further #get's would block forever." \
        unless @in.queued?

    rescue Errno::EPIPE
      direction_error 'Cannot get data from pipe. Already closed that end?'
    end
    
    def close
      close_write
      close_read
    end

  private
    def init_in_and_out
      serializer = ObjectIO::Serializer.new
      @in = ObjectIO::Reader.new(serializer) { fds.r }
      @out = ObjectIO::Writer.new(serializer) { fds.w }
    end
      
    def close_write
      return unless fds.w
      fds.w.close

      fds.w = nil
      @out = nil
    end
    
    def close_read
      return unless fds.r
      fds.r.close

      fds.r = nil
      @in = nil
    end
  
    # # Tries hard to empty the pipe and to store incoming messages in 
    # # @waiting_messages.
    # #
    # def process_inbound_nonblock
    #   buffer = fds.r.read_nonblock(1024*1024*1024)
    # 
    #   while buffer.size > 0
    #     @waiting_messages << transport_unpack(buffer)
    #   end
    rescue EOFError
      # We've just hit end of file in the pipe. That means that all write 
      # ends have been closed. 
      communication_error "All write ends for this pipe have been closed. "+
        "Further #get's would block forever." \
        unless queued?
    # rescue Errno::EAGAIN
    #   # Catch and ignore this: fds.r is not ready and read would block.
    # end
  end
  
  class Channel::Pipe::Identifier
    def initialize(channel)
      @objid = channel.object_id
    end
    
    def resolve
      ObjectSpace._id2ref(@objid).dup
    rescue RangeError
      raise Cod::InvalidIdentifier, 
        "Could not reference channel. Either it was garbage collected "+
        "or it never existed in this process."
    end
  end
end