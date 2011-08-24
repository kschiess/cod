module Cod
  # A topic in a directory. 
  #
  class Topic
    attr_reader :answers, :directory
    attr_reader :match_expr
    attr_reader :identifier
    attr_reader :subscription
    attr_reader :renew_countdown
    
    # Creates a topic that subscribes to a part of a directory. The match_expr
    # decides which messages get forwarded to this topic, it limits the 
    # topic to a subset of the messages in the directory. 
    # 
    # Parameters: 
    #   match_expr        :: Topic to subscribe
    #   directory_channel :: Directory channel
    #   answer_channel    :: Where the messages for this topic get sent
    #   opts              :: See below
    #
    # Available options are: 
    #   :renew            :: Renew the subscription every n seconds. 
    # 
    def initialize(match_expr, directory_channel, answer_channel, opts={})
      @directory, @answers = directory_channel, answer_channel
      @match_expr = match_expr
      @identifier = Cod.uuid
      @subscription = Directory::Subscription.new(
        match_expr, answers, @identifier)
      
      # Default is to renew subscriptions every 30 minutes
      @renew_countdown = Directory::Countdown.new(opts[:renew] || 30*60)
      renew_countdown.start
      
      subscribe
    end
    
    # Subscribes this topic to the directory's messages. This gets called upon
    # initialization and must not be called again. 
    #
    def subscribe(status=:new)
      directory.put [
        :subscribe, subscription, status]

      # Start counting down to next subscription renewal
      renew_countdown.start
    end
    def renew_subscription
      subscribe(:refresh)
    end
    def renewal_needed?
      renew_countdown.elapsed?
    end

    # Reads the next message from the directory that matches this topic. 
    #
    def get(opts={})
      # Read one message from the channel
      subscription_id, message = next_message(opts)
      # Answer back with a ping (so the directory knows we're still there)
      directory.put [:ping, subscription_id]
      
      return message
    end
    def next_message(opts)
      if t=opts[:timeout]
        timeout_at = Time.now + t
        timeout    = [t, renew_countdown.run_time].min
      else
        timeout_at = nil
        timeout    = renew_countdown.run_time
      end

      loop do
        renew_subscription if renewal_needed?
        
        begin
          return answers.get(opts.merge(:timeout => timeout))
        rescue Cod::Channel::TimeoutError
          raise if timeout_at && Time.now > timeout_at
          # DO NOTHING
        end
      end

      fail "NOT REACHED"
    end
    
    # Closes all resources used by the topic. 
    #
    def close
      directory.close
      answers.close
    end
  end
end