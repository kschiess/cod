class Cod::Directory
  # Represents a subscription to a directory. 
  #
  class Subscription
    attr_reader :matcher
    attr_reader :channel
    attr_reader :countdown
    
    def initialize(matcher, channel)
      @matcher = matcher
      @channel = channel
      @countdown = Countdown.new
    end
    
    def ===(other)
      matcher === other
    end
    
    def identifier
      object_id
    end
    
    def put(msg)
      countdown.start
      
      # Envelope the message to send this subscription id along
      channel.put [identifier, msg]
    end
    
    # Is this subscription stale? Staleness is determined by an internal
    # countdown since last #put operation. 
    #
    def stale?(now=Time.now)
      countdown.running? && countdown.elapsed?(now)
    end
   
    # Tells the subscription that the other end has sent back a ping. This 
    # always marks the subscription alive. 
    #
    def ping(now= Time.now)
      # Stop the countdown where it is. If it has elapsed?, the subscription
      # will be marked as stale?
      countdown.stop(now)
    end
  end
end