
begin
  require 'beanstalk-client'
rescue LoadError
  fail "You should install the gem 'beanstalk-client' to use Cod::Channel::Beanstalk."
end

module Cod
  class Channel::Beanstalk < Channel::Base
    NONBLOCK_TIMEOUT = 0.01
    
    # Connection instance that is in use for this channel.
    attr_reader :connection

    # Name of the queue on the beanstalk server
    attr_reader :tube_name
    
    def initialize(reference, name=nil)
      @reference = reference
      @connection = reference.connection
      @tube_name = (name || gen_anonymous_name('beanstalk')).freeze
    end
    
    def put(message)
      buffer = serialize(message)
      connection.put(tube_name, buffer)
    end
    
    def waiting?
      connection.waiting?(tube_name)
    end
    
    def get
      message = connection.get(tube_name)
      return deserialize(message)
    end
    
    def close
      # Free this reference to the connection. If the count drops to zero, 
      # this will trigger a #close on the connection. 
      @reference.close
      @connection = @reference = nil
    end

    def identifier
      identifier_class.new(connection.url, tube_name)
    end
  private
    def gen_anonymous_name(base)
      base + ".anonymous"
    end
  end

  class Channel::Beanstalk::Identifier
    def initialize(url, tube_name)
      @url, @tube_name = url, tube_name
    end
    
    def resolve
      Channel::Beanstalk.new(@url, @tube_name)
    end
  end
end