require 'at_fork'

# The core concept of Cod are 'channels'. (Cod::Channel::Base) You can create
# such channels on top of the various transport layers. Once you have such a
# channel, you #put messages into it and you #get messages out of it. Messages
# are retrieved in FIFO manner, making channels look like a communication pipe
# most of the time. 
#
# Cod also brings a few abstractions layered on top of channels: You can use
# channels to present 'services' (Cod::Service) to the network: A service is a
# simple one or two way RPC call. (one way = asynchronous) You can also use
# channels to run a 'directory' (Cod::Directory) where processes subscribe to
# information using a filter. They then get information that matches their
# filter written to their inbound channel. (also called pub/sub)
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
  # This gets raised in #create_reference when the identifier passed in is
  # either invalid (has never existed) or when it cannot be turned into an
  # object instance. (Because it might have been garbage collected or other
  # such reasons)
  #
  class InvalidIdentifier < StandardError; end
  
  # Creates a beanstalkd based channel. Messages are written to a tube and 
  # read from it. This channel is read/write. Multiple readers will obtain
  # messages in a round-robin fashion from the beanstalk server. 
  #
  # Returns an instance of the Cod::Channel::Beanstalk class.
  #
  # Example: 
  #   chan = Cod.beanstalk('localhost:11300', 'my_tube')
  #
  def beanstalk(url, name)
    context.beanstalk(url, name)
  end
  module_function :beanstalk
  
  # Creates a IO.pipe based channel. Messages are written to one end of the 
  # pipe and come out on the other end. This channel can have only one reader, 
  # but of course multiple writers. Also, once you either write or read from 
  # such a channel, it will not be available for the other operation anymore. 
  #
  # A common trick is to #dup the channel before using it to either read or
  # write, so that the copy can still be used for both operations. 
  #
  # Note that Cod.pipe channels are usable from process childs (#fork) as 
  # well. As such, they are ideally suited for process control. 
  #
  # Returns an instance of the Cod::Channel::Pipe class.
  #
  # Example: 
  #   chan = Cod.pipe
  # 
  def pipe(name=nil)
    context.pipe(name)
  end
  module_function :pipe
  
  def tcp(destination)
    context.tcp(destination)
  end
  module_function :tcp
  
  def tcpserver(bind_to)
    context.tcpserver(bind_to)
  end
  module_function :tcpserver
  
  def context
    @convenience_context ||= Context.new
  end
  module_function :context
  
  # For testing mainly
  #
  def reset
    @convenience_context = nil
  end
  module_function :reset
end

module Cod::Connection; end
require 'cod/connection/beanstalk'

require 'cod/object_io'

require 'cod/channel'
require 'cod/channel/base'
require 'cod/channel/pipe'
require 'cod/channel/beanstalk'
require 'cod/channel/tcpconnection'
require 'cod/channel/tcpserver'

require 'cod/context'
require 'cod/client'

require 'cod/service'

require 'cod/directory'
require 'cod/directory/subscription'
require 'cod/topic'