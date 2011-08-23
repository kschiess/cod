module Cod
  # A topic in a directory. 
  #
  class Topic
    attr_reader :answers, :directory
    attr_reader :match_expr
    def initialize(match_expr, directory_channel, answer_channel)
      @directory, @answers = directory_channel, answer_channel
      @match_expr = match_expr
      
      subscribe
    end
    
    # Subscribes this topic to the directory's messages. This gets called upon
    # initialization and must not be called again. 
    #
    def subscribe
      directory.put [
        :subscribe, Directory::Subscription.new(match_expr, answers)]
    end

    # Reads the next message from the directory that matches this topic. 
    #
    def get(opts={})
      answers.get(opts)
    end
    
    # Closes all resources used by the topic. 
    #
    def close
      directory.close
      answers.close
    end
  end
end