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
      @writer = ObjectIO::Writer.new(serializer) { reconnect }
      @reader = ObjectIO::Reader.new(serializer) { reconnect }
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
      # TODO throws Errno::ECONNREFUSED if the other end doesn't exist (yet)
      # p :reconnect
      @connection ||= TCPSocket.new(*destination)
    rescue Errno::ECONNREFUSED
      nil
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