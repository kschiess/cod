module Cod
  # A topic in a directory. 
  #
  class Topic
    attr_reader :answers, :directory
    attr_reader :match_expr
    attr_reader :identifier
    attr_reader :subscription
    
    def initialize(match_expr, directory_channel, answer_channel)
      @directory, @answers = directory_channel, answer_channel
      @match_expr = match_expr
      @identifier = Cod.uuid
      @subscription = Directory::Subscription.new(
        match_expr, answers, @identifier)
      
      subscribe
    end
    
    # Subscribes this topic to the directory's messages. This gets called upon
    # initialization and must not be called again. 
    #
    def subscribe
      directory.put [
        :subscribe, subscription, :new]
    end
    def renew_subscription
      directory.put [
        :subscribe, subscription, :refresh]
    end

    # Reads the next message from the directory that matches this topic. 
    #
    def get(opts={})
      # Read one message from the channel
      subscription_id, message = answers.get(opts)
      # Answer back with a ping (so the directory knows we're still there)
      directory.put [:ping, subscription_id]
      
      return message
    end
    
    # Closes all resources used by the topic. 
    #
    def close
      directory.close
      answers.close
    end
  end
end