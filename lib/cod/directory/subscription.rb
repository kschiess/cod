module Cod
  # Represents a subscription to a directory. 
  #
  class Directory::Subscription
    attr_reader :matcher
    attr_reader :channel
    
    def initialize(matcher, channel)
      @matcher = matcher
      @channel = channel
    end
    
    def ===(other)
      matcher === other
    end
    
    def put(msg)
      channel.put msg
    end
  end
end