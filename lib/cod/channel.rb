module Cod
  # Channels transport ruby objects from one end to the other. The
  # communication setup varies a bit depending on the transport used for the
  # channel, but the interface you interact with doesn't vary. You can #put
  # messages into a channel and you then #get them out of it. 
  #
  # Synopsis: 
  #   channel.put [:a, :ruby, :object]
  #   channel.get # => [:a, :ruby, :object]
  #
  # By default, channels will serialize the messages you give them using
  # Marshal.dump and Marshal.load. You can change this by passing your own
  # serializer to the channel upon construction; see SimpleSerializer for a
  # description of the interface such a serializer needs to implement. 
  # 
  # This class (Cod::Channel) is the abstract superclass of all Cod channels.
  # It doesn't have a transport by its own, but implements the whole interface
  # for documentation purposes.
  #
  class Channel
    # Obtains one message from the channel. If the channel is empty, but
    # theoretically able to receive more messages, blocks forever. But if the
    # channel is somehow broken, an exception is raised. 
    #
    def get
      abstract_method_error
    end
    
    # Puts one message into a channel. 
    #
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