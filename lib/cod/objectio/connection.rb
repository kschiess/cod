module Cod::ObjectIO::Connection
  class Pool
    include Enumerable 
    
    attr_reader :connect_action
    attr_reader :connections
    
    # Example: 
    #   Connection::Single.new { TCPSocket.new('...') }
    #   Connection::Pool.new { socket.accept }
    #   
    def initialize(&connect_action)
      raise ArgumentError unless connect_action
      
      @connect_action = connect_action
      @connections = []
    end
    
    def size
      @connections.size
    end
    
    def report_failed(connection)
      @connections.delete_if { |e| e == connection }
    end
    
    def accept
      @connections += call_connect
    end
    
    def each(&block)
      @connections.each(&block)
    end
    
    # Closes all connections in this pool. 
    #
    def close
      self.each do |connection|
        begin
          connection.close 
        rescue IOError
          # Maybe someone else that shares this connection closed it already?
          # DO NOTHING
        end
      end
    end
  private
    # Calls the connect_action block and normalizes the result to be either
    # an array or nil. 
    #
    def call_connect
      result = connect_action[]
      if result
        return [result].flatten
      end
      
      return nil
    end
  end
    
  # Implements a single connection that is retried on failure for a number
  # of times. 
  #
  class Single < Pool
    MAX_FAILURES = 10
    
    def initialize(&connect_action)
      super
      
      @connected = false
      @failures = 0
    end
    
    def report_failed(connection)
      super

      @failures += 1
      @connected = false
    end
    
    def accept
      return if @connected
      
      # How many times have we reconnected? Maybe just give up. 
      permanent_connection_error if @failures >= MAX_FAILURES

      # Try and make a new connection: Returns it on success.
      new_connection = call_connect
      if new_connection
        @connected = true
        @connections += new_connection
        return
      end
      
      # No new connection could be made. Count this as a failure. 
      @failures += 1
      return
    end
    
  private
    def permanent_connection_error
      raise Cod::Channel::CommunicationError, 
        "Permanent connection failure: Giving up."
    end
  end
end