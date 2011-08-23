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
    
    # Sends the message to all subscribers that listen to this topic. Returns
    # the number of subscribers this message has been sent to. 
    #
    def publish(topic, message)
      process_control_messages

      n = 0
      failed_subscriptions = []
      for subscription in @subscriptions
        begin
          if subscription === topic
            subscription.put message
            n += 1
          end
        # TODO reenable this with more specific exception list.
        rescue Cod::Channel::DirectionError
          # Writing message failed; remove the subscription. 
          failed_subscriptions << subscription
        end
      end
      
      process_control_messages
      
      remove_subscriptions(failed_subscriptions)
      return n
    end
    
    # Closes all resources used by the directory. 
    #
    def close
      channel.close
    end

    # Mostly for use during tests. 
    def subscribe(subscription)
      @subscriptions << subscription
    end

  private
    def remove_subscriptions(failed)
      @subscriptions.delete_if { |e| failed.include?(e) }
    end
  
    def process_control_messages
      while channel.waiting?
        cmd, *rest = channel.get(timeout: 0.1)
        case cmd
          when :subscribe
            subscription = rest.first
            subscribe subscription
          when :ping
            ping_id = rest.first
            subscriptions.
              find { |sub| sub.identifier == ping_id }.
              ping
        else 
          warn "Unknown command received: #{cmd.inspect} (#{rest.inspect})"
        end
      end
    rescue ArgumentError
      # Probably we could not create a duplicate of a serialized channel. 
      # Ignore this round of subscriptions. 
    end
  end
end