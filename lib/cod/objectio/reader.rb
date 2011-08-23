module Cod::ObjectIO
  # Reads objects from one or more IO streams. 
  #
  class Reader
    attr_reader :waiting_messages
    attr_reader :pool
    
    # Initializes an object reader that reads from one or several IO objects. 
    #
    # Example: 
    #   connection = Connection::Pool.new { make_new_connection }
    #   reader = Reader.new(serializer, connection)
    #    
    def initialize(serializer, conn_pool)
      @serializer = serializer
      @waiting_messages = []
      @pool = conn_pool
    end    
    
    def get(opts={})
      return waiting_messages.shift if queued?
      
      start_time = Time.now
      loop do
        read_from_wire opts
        
        # Early return in case we have a message waiting
        return waiting_messages.shift if queued?
        
        if opts[:timeout] && (Time.now-start_time) > opts[:timeout]
          raise Cod::Channel::TimeoutError, 
            "No messages waiting in pipe."
        end
      end
      
      fail "NOTREACHED"
    end
    
    def waiting?
      read_from_wire
      queued?
    end
    
    def queued?
      ! waiting_messages.empty?
    end
    
    def close
      @pool.close
    end
    
  private 
    
    # Checks if data is waiting and processes messages. 
    #
    def read_from_wire(opts={})
      # Establish new connections and register them
      @pool.accept

      # Process all waiting data
      process_nonblock(@pool.connections)
    end
    
    # Reads all data waiting in each io in the ios array. 
    #
    def process_nonblock(ios)
      ios.each do |io|
        process_nonblock_single(io)
      end
    end
    
    # Reads all data waiting in a single io. 
    #
    def process_nonblock_single(io)
      buffer = io.read_nonblock(1024*1024*1024)

      sio = StringIO.new(buffer)
      while not sio.eof?
        waiting_messages << deserialize(io, sio)
      end
    rescue Errno::EAGAIN
      # read failed because there was no data. This is expected. 
      return
    rescue EOFError
      @pool.report_failed(io)
    end
        
    # Deserializes a message (in message format, string) into the object that
    # was transmitted. Overwrite this message if you want to control the 
    # message format. 
    #
    def deserialize(*args)
      @serializer.deserialize(*args)
    end
  end
end