module Cod
  # A directory where one can publish messages given a topic string. 
  #
  # The channel given will be where people should subscribe.
  #
  class Directory
    # The channel the directory receives subscription messages on. 
    #
    attr_reader :channel
    
    def initialize(channel)
      @channel = channel
      @subscriptions = []
    end
    
    # Sends the message to all subscribers that listen to this topic. 
    #
    def publish(topic, message)
      handle_subscriptions
      
      for subscription in @subscriptions
        subscription.put message if subscription === topic
      end
    end
    
    # Closes all resources used by the directory. 
    #
    def close
      channel.close
    end
    
  private
  
    def handle_subscriptions
      while channel.waiting?
        subscribe channel.get
      end
    end
    
    def subscribe(subscription)
      @subscriptions << subscription
    end
  end
end