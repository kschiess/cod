module Cod
  def beanstalk(url, name=nil)
    context.beanstalk(url, name)
  end
  module_function :beanstalk
  
  def pipe(name=nil)
    context.pipe(name)
  end
  module_function :pipe
  
  def create_reference(identifier)
    context.create_reference(identifier)
  end
  module_function :create_reference
  
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

require 'cod/channel'
require 'cod/channel/base'
require 'cod/channel/pipe'
require 'cod/channel/fifo'
require 'cod/channel/beanstalk'

require 'cod/context'
require 'cod/service'
require 'cod/topic'