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
  # Creates a pipe connection that is visible to this process and its
  # children. (see Cod::Pipe)
  #
  def pipe
    Cod::Pipe.new
  end
  module_function :pipe
  
  # Creates a tcp connection to the destination and returns a channel for it.
  # (see Cod::TcpClient)
  #
  def tcp(destination, serializer=nil)
    Cod::TcpClient.new(
      destination, 
      serializer || SimpleSerializer.new)
  end
  module_function :tcp
  
  # Creates a tcp listener on bind_to and returns a channel for it. (see
  # Cod::TcpServer)
  #
  def tcp_server(bind_to)
    Cod::TcpServer.new(bind_to)
  end
  module_function :tcp_server

  # Creates a channel based on the beanstalkd messaging queue. (see
  # Cod::Beanstalk::Channel)
  # 
  def beanstalk(tube_name, server=nil)
    Cod::Beanstalk::Channel.new(tube_name, server||'localhost:11300')
  end
  module_function :beanstalk

  # Creates and returns a service (server process). (see Cod::Service)
  #
  def service(*args)
    Cod::Service.new(*args)
  end
  module_function :service

  # Creates and returns a service client. (see Cod::Service and Cod::Service::Client)
  #
  def client(*args)
    Cod::Service::Client.new(*args)
  end
  module_function :client


  # Indicates that the given channel is write only. This gets raised on 
  # operations like #put.
  #
  class WriteOnlyChannel < StandardError
    def initialize
      super("This channel is write only, attempted read operation.")
    end
  end
  
  # Indicates that the channel is read only. This gets raised on operations
  # like #get. 
  #
  class ReadOnlyChannel < StandardError
    def initialize
      super("This channel is read only, attempted write operation.")
    end
  end
end

require 'cod/select_group'
require 'cod/select'

require 'cod/channel'

require 'cod/simple_serializer'

require 'cod/pipe'

require 'cod/tcp_client'
require 'cod/tcp_server'

require 'cod/beanstalk'

require 'cod/service'
