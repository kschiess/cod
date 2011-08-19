require 'cod/channel/tcp'

module Cod
  # A channel based on a tcp connection.
  #
  # Also see Channel::Base for more documentation. 
  #
  class Channel::TCPConnection < Channel::Base
    include Channel::TCP
    
    # A <host, port> tuple: The target of this connection. 
    #
    attr_reader :destination
    
    def initialize(destination_or_connection)
      if destination_or_connection.respond_to?(:to_str)
        @destination = split_uri(destination_or_connection)
        @connection = nil
      else
        @destination = nil
        @connection = destination_or_connection
      end
      
      serializer = ObjectIO::Serializer.new
      connection_pool = ObjectIO::Connection::Single.new { connect }
      @writer = ObjectIO::Writer.new(serializer, connection_pool)
      @reader = ObjectIO::Reader.new(serializer, connection_pool) 
    end
    
    def put(message)
      # TODO Errno::EPIPE raised after a while when the receiver goes away. 
      @writer.put(message)
    end
    
    def get(opts={})
      @reader.get(opts)
    end
    
    def waiting?
      # TODO EOFError is thrown when the other end has gone away
      @reader.waiting?
    end
    
    def connected?
      # Trigger an attempt to read from the socket. If it has been
      # disconnected, this should throw an error. If the call to reconnect
      # then fails, connection is set to nil.
      @reader.waiting?
      
      @connection != nil
    end
    
    def close
      @connection.close if @connection
      @connection = nil
    end
    
    def identifier
      Identifier.new(destination)
    end
    
  private
    def connect
      if destination
        TCPSocket.new(*destination) 
      else
        @connection
      end
    end
  end

  class Channel::TCPConnection::Identifier
    def initialize(destination)
      @destination = destination
    end
    
    def resolve
      # If we've been sent to our own server end, assume the role of the
      # socket on that side. This is achieved by inserting the self into 
      # the stream of deserialized objects and having the transformer 
      # (attached to the serializer, see ObjectIO::Serializer) transform
      # it into a valid connection object. 
      self
    end
  end
end