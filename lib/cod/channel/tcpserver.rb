require 'cod/channel/tcp'

module Cod
  # A channel based on a passive tcp server (listening).
  #
  class Channel::TCPServer < Channel::Base
    include Channel::TCP
    
    # The <host, port> tuple this server is bound to. 
    attr_reader :bind_to
    
    # The actual TCPServer instance
    attr_reader :server
    
    # Sockets that are open to clients
    attr_reader :connections
    
    def initialize(bind_to)
      @bind_to = split_uri(bind_to)
      # All messages that have been read from the wire but not delivered.
      @waiting_messages = []
      # All connected sockets. 
      @connections = []
      
      connect
    end
    
    def initialize_copy(from)
      not_implemented
    end
    
    def put(message)
      communication_error "You cannot write to a server channel."
    end
    
    def get(opts={})
      return @waiting_messages.shift if queued?

      start_time = Time.now
      loop do
        # p [:looping, @waiting_messages, connections.size]
        read_from_wire(opts)
        return @waiting_messages.shift if queued?
        
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
    
    def close
      server.close
      connections.each do |connection|
        connection.close
      end
      @server = nil
      @connections = []
    end
    
    def identifier
      not_implemented
    end
    
  private
  
    # Accepts new connections and processes (tries to) messages from all 
    # clients. Nonblocking. 
    #
    def read_from_wire(opts={})
      # Accept new clients
      accept_connections
      
      # Wait for sockets to have data
      ready = IO.select(connections, nil, [], 0.1)
      
      # Read all ready sockets
      process_inbound_nonblock(ready.first) if ready
    end
  
    # Tries to read from all sockets and empty their queues, instead buffering
    # messages in @waiting_messages.
    #
    def process_inbound_nonblock(sockets)
      sockets.each do |socket|
        buffer = socket.read_nonblock(1024*1024*1024)

        while buffer.size > 0
          @waiting_messages << transport_unpack(buffer)
        end
      end
    end

    # Accept all pending connects and stores them in the connections array. 
    #
    def accept_connections
      loop do
        connection = server.accept_nonblock
        self.connections << connection
      end
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
      # Means that no connects are pending. Ignore, since this is exactly
      # the termination condition for this method. 
    end
  
    def queued?
      ! @waiting_messages.empty?
    end
  
    def connect
      @server = TCPServer.new(*bind_to)
    end
  end
end