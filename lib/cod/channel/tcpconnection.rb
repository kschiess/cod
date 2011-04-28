require 'cod/channel/tcp'

module Cod
  # A channel based on a tcp connection.
  #
  class Channel::TCPConnection < Channel::Base
    include Channel::TCP
    
    # A <host, port> tuple: The target of this connection. 
    #
    attr_reader :destination
    
    # The tcp connection to the target
    #
    attr_reader :connection
    
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
          buffer = transport_pack(message)
          conn.write(buffer)
          
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
      connection.close if connection
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
  
    def with_connection
      @connection = TCPSocket.new(*destination)
      yield connection
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
  end
end