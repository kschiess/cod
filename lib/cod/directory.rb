module Cod
  # A directory where one can publish messages given a topic string. 
  #
  # The channel given will be where people should subscribe.
  #
  class Directory
    # The channel the directory receives subscription messages on. 
    #
    attr_reader :channel
    
    # Subscriptions this directory handles. 
    #
    attr_reader :subscriptions
    
    def initialize(channel)
      @channel = channel
      @subscriptions = []
    end
    
    # Sends the message to all subscribers that listen to this topic. 
    #
    def publish(topic, message)
      handle_subscriptions
      
      failed_subscriptions = []
      for subscription in @subscriptions
        begin
          subscription.put message if subscription === topic
        rescue => exception
          # Writing message failed; remove the subscription. 
          failed_subscriptions << subscription
        end
      end
      
      remove_subscriptions(failed_subscriptions)
    end
    
    # Closes all resources used by the directory. 
    #
    def close
      channel.close
    end
    
  private
  
    def remove_subscriptions(failed)
      @subscriptions.delete_if { |e| failed.include?(e) }
    end
  
    def handle_subscriptions
      while channel.waiting?
        subscribe channel.get
      end
    rescue ArgumentError
      # Probably we could not create a duplicate of a serialized channel. 
      # Ignore this round of subscriptions. 
    end
    
    def subscribe(subscription)
      @subscriptions << subscription
    end
  end
end