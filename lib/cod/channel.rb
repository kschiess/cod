module Cod
  # Abstract superclass for all channels. This class implements some
  # functionality that is independent of the transport used in the channel.
  #
  class Channel
    def get
      abstract_method_error
    end
    def put(msg)
      abstract_method_error
    end
    
    # Interact with a channel by first writing msg to it, then reading back 
    # the other ends answer. 
    #
    def interact(msg)
      put msg
      get
    end
    
  private 
    def abstract_method_error
      fail "Abstract method called"
    end
  end
end