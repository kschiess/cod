module Cod::ObjectIO
  # Reads objects from one or more IO streams. 
  #
  class Reader
    attr_reader :waiting_messages
    attr_reader :registered_ios
    
    # Initializes an object reader that reads from one or several IO objects. 
    # You can either pass the io object in the constructor (io) or you can 
    # provide the instance with a block that is called each time a read is
    # attempted. The block should return an array of IO objects to also read
    # from. 
    #
    # Example: 
    #   reader = Reader.new { make_connection }
    #    
    def initialize(serializer, io=nil, &block)
      @serializer = serializer
      @waiting_messages = []
      @establish_block = block
      @registered_ios = Set.new
      
      register io if io
    end    
    
    # Called before each attempt to read from the wire. This should return 
    # the IO objects that need to be considered when reading. 
    #
    def establish
      sockets = @establish_block && @establish_block.call(@io) ||
        nil
      
      [sockets].flatten
    end
    
    def register(ios)
      return unless ios
      ios.each do |io|
        registered_ios << io
      end
    end
    
    def unregister(ios)
      ios.each do |io|
        registered_ios.delete(io)
      end
    end
    
    def get(opts={})
      return waiting_messages.shift if queued?
      
      start_time = Time.now
      loop do
        # p [:looping, opts]
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
      @registered_ios.each { |io| io.close }
    end
    
  private 
    
    # Checks if data is waiting and processes messages. 
    #
    def read_from_wire(opts={})
      # Establish new connections and register them
      register establish

      # Wait for sockets to have data
      ready_read, _, _ = IO.select(Array(registered_ios), nil, nil, 0.1)
      
      # Read all ready sockets
      process_nonblock(ready_read) if ready_read
    end
    
    # Reads all data waiting in each io in the ios array. 
    #
    def process_nonblock(ios)
      ios.each do |io|
        buffer = io.read_nonblock(1024*1024*1024)

        sio = StringIO.new(buffer)
        while not sio.eof?
          waiting_messages << deserialize(io, sio)
        end
      end
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