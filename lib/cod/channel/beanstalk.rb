
begin
  require 'beanstalk-client'
rescue LoadError
  fail "You should install the gem 'beanstalk-client' to use Cod::Channel::Beanstalk."
end

module Cod
  class Channel::Beanstalk < Channel::Base
    NONBLOCK_TIMEOUT = 0.01
    
    # Url that was used to connect to the beanstalk server
    attr_reader :url
    
    # Connection to the beanstalk server (Beanstalk::Connection)
    attr_reader :beanstalk

    # Name of the queue on the beanstalk server
    attr_reader :tube_name
    
    def initialize(url, name=nil)
      @url = url.freeze
      @tube_name = (name || gen_anonymous_name('beanstalk')).freeze
      @beanstalk = Beanstalk::Connection.new(url, tube_name)
    end
    
    def put(message)
      buffer = serialize(message)
      beanstalk.put(buffer)
    end
    
    def waiting?
      !! beanstalk.peek_ready
    end
    
    def get
      job = beanstalk.reserve
      job.delete
      
      return deserialize(job.body)
    end
    
    def close
      beanstalk.close
      @beanstalk = nil
    end
  private
    def gen_anonymous_name(base)
      base + ".anonymous"
    end
  end
end