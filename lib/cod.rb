require 'uuid'

# The core concept of Cod are 'channels'. (Cod::Channel::Base) You can create
# such channels on top of the various transport layers. Once you have such a
# channel, you #put messages into it and you #get messages out of it. Messages
# are retrieved in FIFO manner, making channels look like a communication pipe
# most of the time. 
#
# Cod also brings a few abstractions layered on top of channels: You can use
# channels to present 'services' (Cod::Service) to the network: A service is a
# simple one or two way RPC call. (one way = asynchronous) 
#
# Cod channels are serializable whereever possible. If you want to tell
# somebody where to write his answers and/or questions to, send him the
# channel! This is really powerful and used extensively in constructing the
# higher order primitives. 
#
# The goal of Cod is that you have to know only very few things about the
# network (the various transports) to be able to construct complex things. It
# handles reconnection and reliability for you. It also translates cryptic OS
# errors into plain text messages where it can't just handle them. This should
# give you a clear place to look at if things go wrong. Note that this can
# only be ever as good as the sum of situations Cod has been tested in.
# Contribute your observations and we'll come up with a way of dealing with
# most of the tricky stuff!
#
module Cod
  # Creates a pipe connection that is visible to this process and its children. 
  #
  def pipe
    Cod::Pipe.new
  end
  module_function :pipe
  
  # Creates a tcp connection to the destination and returns a channel for it. 
  #
  def tcp(destination)
  end
  module_function :tcp
  
  # Creates a tcp listener on bind_to and returns a channel for it. 
  #
  def tcpserver(bind_to)
  end
  module_function :tcpserver
end

require 'cod/pipe'