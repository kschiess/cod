require 'cod/channel/tcp'

module Cod
  # A channel based on a tcp connection.
  #
  class Channel::TCPConnection < Channel::Base
    include Channel::TCP
    
    # A <host, port> tuple: The target of this connection. 
    #
    attr_reader :destination
    
    def initialize(destination)
      @destination = split_uri(destination)
      
      @connection = nil
      
      @writer = ObjectIO::Writer.new { reconnect }
      @reader = ObjectIO::Reader.new { reconnect }
    end
    
    def put(message)
      @writer.put(message)
    end
    
    def get(opts={})
      @reader.get(opts)
    end
    
    def close
      @connection.close if @connection
      @connection = nil
    end
    
    def identifier
      Identifier.new(destination)
    end
    
  private
    # Establishes connection in @connection. If a previous connection is 
    # in error state, it attempts to make a new connection. 
    #
    def reconnect
      @connection ||= TCPSocket.new(*destination)
    end
  end

  class Channel::TCPConnection::Identifier
    def initialize(destination)
      @destination = destination
    end
    
    def resolve
      # If we've been sent to our own server end, assume the role of the
      # socket on that side. 
      
      # Otherwise: Fail miserably. The expectation would be that if someone
      # wrote to us, they would be able to connect to the read end on the
      # other side. 
      raise Channel::CommunicationError,
        "Unable to find a way of communicating back through channel."
    end

    def resolve_socket(socket)
      Channel::TCPConnection::Simple.new(socket)
    end
  end
end