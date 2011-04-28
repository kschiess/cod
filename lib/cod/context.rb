require 'weakref'

module Cod
  # Channels inside a context know each other and can be looked up by their
  # identifier. Context is also responsible for holding connections and for
  # doing background work. For most purposes, you will only need one context; 
  # by using methods on the Cod module directly, you implicitly hold a context
  # and call methods there. 
  #
  class Context
    
    def self.install_at_fork(ref)
      at_fork do |old_handler|
        old_handler.call rescue nil
        
        begin
          ref.reset
        rescue WeakRef::RefError
          # IGNORED EXCEPTION
        end
      end
    end
    
    def initialize
      @connections = {}
      
      self.class.install_at_fork(WeakRef.new(self))
    end
    
    def pipe(name=nil)
      Cod::Channel::Pipe.new(name)
    end
    
    def beanstalk(url, name=nil)
      Cod::Channel::Beanstalk.new(
        connection(:beanstalk, url), name)
    end
    
    def tcp(destination)
      Cod::Channel::TCPConnection.new(destination)
    end

    def tcpserver(bind_to)
      Cod::Channel::TCPServer.new(bind_to)
    end
    
    def reset
      @connections = {}
    end
    
  private
    # Returns a connection to a system identified by type and url. Currently, 
    # connections are never released or closed. This is only a minor drawback
    # since there will be few of them. (considering we only use this for 
    # beanstalk) 
    #
    def connection(type, url)
      key = connection_key(type, url)
      
      connection = @connections[key]
      return connection if connection
    
      produce_connection(type, url).tap { |connection|
        @connections.store(key, connection) }
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