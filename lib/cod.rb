require 'at_fork'

# See Cod::Channel::Base for more documentation. 
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