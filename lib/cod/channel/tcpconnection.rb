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
      @waiting_messages = []
    end
    
    def initialize_copy(from)
      not_implemented
    end
    
    def put(message)
      queue message
      
      with_connection do |conn|
        loop do
          message = @waiting_messages.shift
          conn.put(message)
          
          break unless queued?
        end
      end
    rescue Errno::ECONNREFUSED
      # No listening end at destination. Wait until a connection can be made.
    end
    
    def get(opts={})
      not_implemented
    end
    
    def waiting?
      not_implemented
    end
    
    def close
      @connection.close if @connection
      @connection = nil
    end
    
    def identifier
      Identifier.new(destination)
    end
    
    def may_transmit?(channel)
      channel == self
    end
    
  private
    # Put a message into the send queue. 
    #
    def queue(message)
      @waiting_messages << message
    end
    
    # Are there messages queued?
    # 
    def queued?
      ! @waiting_messages.empty?
    end
  
    # Yields a working TCPConnection::Simple instance to the block given. 
    #
    def with_connection
      @connection ||= begin
        socket = TCPSocket.new(*destination)
        Simple.new(socket)
      end
      yield @connection
    end
  end

  # A simple TCP connection that only works as long as the socket it stores
  # is connected. Once the connection breaks, expect nothing but exceptions. 
  #
  class Channel::TCPConnection::Simple < Channel::Base
    # The tcp connection to the target
    #
    attr_reader :socket
    
    def initialize(socket)
      @socket = socket
    end
    
    def put(message)
      buffer = transport_pack(message)
      socket.write(buffer)
    end
    
    def close
      socket.close if socket
      @socket = nil
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