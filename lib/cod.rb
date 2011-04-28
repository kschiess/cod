require 'at_fork'

module Cod
  # This gets raised in #create_reference when the identifier passed in is
  # either invalid (has never existed) or when it cannot be turned into an
  # object instance. (Because it might have been garbage collected or other
  # such reasons)
  #
  class InvalidIdentifier < StandardError; end
  
  def beanstalk(url, name=nil)
    context.beanstalk(url, name)
  end
  module_function :beanstalk
  
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