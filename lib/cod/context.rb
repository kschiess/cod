module Cod
  # Channels inside a context know each other and can be looked up by their
  # identifier. Context is also responsible for holding connections and for
  # doing background work. For most purposes, you will only need one context; 
  # by using methods on the Cod module directly, you implicitly hold a context
  # and call methods there. 
  #
  class Context
    
    def initialize
      @connections = {}
    end
    
    def pipe(name=nil)
      Cod::Channel::Pipe.new(name)
    end
    
    def beanstalk(url, name=nil)
      Cod::Channel::Beanstalk.new(
        connection(:beanstalk, url), name)
    end
    
  private
    # Holds connections to other systems and a reference count. This helps in
    # deciding when we should close the connection. 
    #
    ConnectionRef = Struct.new(:connection, :references) do
      def use
        self.references += 1
      end
      
      def close
        self.references -= 1
        if self.references <= 0
          connection.close
          self.connection = nil
        end
      end
    end
  
    # Returns a connection to a system identified by type and url. 
    #
    def connection(type, url)
      key = connection_key(type, url)

      if ref = @connections[key]
        ref.use
      else
        connection = produce_connection(type, url)
        ref = ConnectionRef.new(connection, 1)
        @connections.store key, ConnectionRef.new(connection)
      end

      return ref
    end
    
    def connection_key(type, url)
      [type, url]
    end
    
    def produce_connection(type, url)
      case type
        when :beanstalk
          return Connection::Beanstalk.new(url)
      end
      
      fail "Tried to produce a connection of unknown type #{type.inspect}."
    end
  end
end