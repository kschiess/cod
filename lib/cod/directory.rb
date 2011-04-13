module Cod
  # A directory where one can publish messages given a topic string. 
  #
  # The channel given will be where people should subscribe.
  #
  class Directory
    def initialize(channel)
    end
    
    # Sends the message to all subscribers that listen to this topic. 
    #
    def publish(topic, message)
    end
    
    # Returns the current number of subscribers for the given topic. If the
    # topic is nil, it returns the total number of subscribers for any topic. 
    # 
    def subscribers(topic=nil)
    end
    
    # Closes all resources used by the directory. 
    #
    def close
    end
  end
end