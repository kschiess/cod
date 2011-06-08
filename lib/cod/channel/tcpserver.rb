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
      
      connect
    end
    
    def get(opts={})
      @oio.get(opts)
    end
    
    def put(message)
      communication_error "You cannot write to the server directly, transmit a "
                          "channel to the server instead."
    end
    
    def waiting?
      @oio.waiting?
    end
    
    def close
      @oio.close
      server.close

      @server = nil
      @oio = nil
    end
    
  private
  
    # Accept all pending connects and stores them in the connections array. 
    #
    def accept_connections(server)
      connections = []
      loop do
        connection = server.accept_nonblock
        connections << connection
      end
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
      # Means that no more connects are pending. Ignore, since this is exactly
      # one of the termination conditions for this method. 
      return connections
    end
  
    def connect
      @server = TCPServer.new(*bind_to)
      @oio = ObjectIO::Reader.new { 
        accept_connections(server)
      }
    end
  end
end