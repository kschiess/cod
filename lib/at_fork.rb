# Extends the Kernel module with an at_fork method for installing at_fork
# handlers. 

module Kernel
  class << self
    def at_fork_handler
      @at_fork_handler ||= proc {}
    end
    def at_fork_handler=(handler)
      @at_fork_handler = handler
    end
  end
  
  def at_fork(&block)
    old_handler = Kernel.at_fork_handler
    Kernel.at_fork_handler = lambda { block.call(old_handler) }
  end
  
  def fork_with_at_fork(&block)
    Kernel.at_fork_handler.call()
    
    fork_without_at_fork do
      Kernel.at_fork_handler = nil
      block.call
    end
  end
  alias fork_without_at_fork  fork
  alias fork                  fork_with_at_fork
end