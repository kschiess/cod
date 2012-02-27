module Cod
  # Channels transport Ruby objects from one end to the other. The
  # communication setup varies a bit depending on the transport used for the
  # channel, but the interface you interact with doesn't vary. You can #put
  # messages into a channel and you then #get them out of it. 
  #
  # = Synopsis
  #
  #   channel.put [:a, :ruby, :object]
  #   channel.get # => [:a, :ruby, :object]
  #
  # By default, channels will serialize the messages you give them using
  # Marshal.dump and Marshal.load. You can change this by passing your own
  # serializer to the channel upon construction; see {SimpleSerializer} for a
  # description of the interface such a serializer needs to implement. 
  # 
  # This class is the abstract superclass of all Cod channels. It doesn't have
  # a transport by its own, but implements the whole interface for
  # documentation purposes.
  #
  class Channel
    # Obtains one message from the channel. If the channel is empty, but
    # theoretically able to receive more messages, blocks forever. But if the
    # channel is somehow broken, an exception is raised. 
    #
    # @return [Object] the next message waiting in the channel
    #
    def get
      abstract_method_error
    end
    
    # Puts one message into a channel. 
    #
    # @param msg [Object] any Ruby object that should be sent as message
    # @return [void]
    #
    def put(msg)
      abstract_method_error
    end
    
    # Interact with a channel by first writing msg to it, then reading back 
    # the other ends answer. 
    #
    # @param msg [Object] any Ruby object that should be sent as message
    # @return [Object] the answer from the other end.
    #
    def interact(msg)
      put msg
      get
    end
    
    # Produces a service that has this channel as communication point. 
    #
    # @return [Cod::Service]
    #
    def service
      abstract_method_error
    end
    
    # Produces a service client that connects to this channel and receives
    # service answers to the channel indicated by answers_to.
    #
    # @param answers_to [Cod::Channel] where to send the answers
    # @return [Cod::Service::Client]
    #
    def client(answers_to)
      abstract_method_error
    end
    
  private 
    def abstract_method_error
      fail "Abstract method called"
    end
  end
end