require 'cod/channel/tcp'

module Cod
  # A channel based on a passive tcp server (listening). 
  #
  # Also see Channel::Base for more documentation. 
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
      @server = TCPServer.new(*@bind_to)

      connection_pool = ObjectIO::Connection::Pool.new { accept_connections(server) }
      serializer = ObjectIO::Serializer.new(self)
      
      super(
        ObjectIO::Reader.new(serializer, connection_pool), 
        nil)
    end
        
    # Sending a message to the server side of a socket is not supported.
    # Transmit the client side channel instance to be able to write back to it
    # on the server side. This overwrites #put in Base for the sole purpose of
    # raising a better error. 
    #
    def put(message)
      communication_error "You cannot write to the server directly, transmit a "
                          "channel to the server instead."
    end
    
    def close
      super
      
      server.close if server
      @server = nil
    end

    def transform(socket, obj)
      if obj.kind_of?(Channel::TCPConnection::Identifier)
        # We've been sent 'a' tcp channel. Assume that it's our own client end
        # that we've been sent and turn it into a channel that communicates
        # back there. 
        return Channel::TCPConnection.new(socket)
      end
      
      return obj
    end
    
    def identifier
      communication_error "TCP server channels cannot be transmitted."
    end
  
  private
    
    # Accept all pending connects and stores them in the connections array. 
    #
    def accept_connections(server)
      connections = []
      loop do
        # Try connecting more sockets. 
        begin
          connections << server.accept_nonblock
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR  
          # Means that no more connects are pending. Ignore, since this is exactly
          # one of the termination conditions for this method. 
          return connections
        end
      end
      
      fail "NOTREACHED: return should be from loop."
    end
  end
end