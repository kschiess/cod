module Cod
  # A topic in a directory. 
  #
  class Topic
    attr_reader :answers, :directory
    def initialize(match_expr, directory_channel, answer_channel)
      @directory, @answers = directory_channel, answer_channel
    end

    # Reads the next message from the directory that matches this topic. 
    #
    def get
    end
    
    # Closes all resources used by the topic. 
    #
    def close
      directory.close
      answers.close
    end
  end
end