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
    
    def identifier
      object_id
    end
    
    def put(msg)
      # Envelope the message to send this subscription id along
      channel.put [identifier, msg]
    end
  end
end