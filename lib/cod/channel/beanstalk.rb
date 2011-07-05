
begin
  require 'beanstalk-client'
rescue LoadError
  fail "You should install the gem 'beanstalk-client' to use Cod::Channel::Beanstalk."
end

module Cod
  # Also see Channel::Base for more documentation. 
  #
  class Channel::Beanstalk < Channel::Base
    NONBLOCK_TIMEOUT = 0.01
    
    # Connection instance that is in use for this channel.
    attr_reader :connection

    # Name of the queue on the beanstalk server
    attr_reader :tube_name
    
    def initialize(connection, name)
      @connection = connection
      @tube_name = name.freeze
      @serializer = ObjectIO::Serializer.new
    end
    
    def initialize_copy(from)
      @connection = from.connection
      @tube_name = from.tube_name
    end
    
    def put(message)
      buffer = @serializer.serialize(message)
      connection.put(tube_name, buffer)
    end
    
    def waiting?
      connection.waiting?(tube_name)
    end
    
    def get(opts={})
      message = connection.get(tube_name, 
        :timeout => opts[:timeout])
      return @serializer.deserialize(nil, message)
    rescue Beanstalk::TimedOut
      raise Channel::TimeoutError, "No messages waiting in #{tube_name}."
    end
    
    def close
      @connection = @reference = nil
    end

    def identifier
      identifier_class.new(connection.url, tube_name)
    end
  end

  class Channel::Beanstalk::Identifier
    def initialize(url, tube_name)
      @url, @tube_name = url, tube_name
    end
    
    def resolve(ctxt=nil)
      raise NotImplementedError, "Explicit context not yet implemented." \
        if ctxt
          
      Cod.beanstalk(@url, @tube_name)
    end
  end
end