# Extends the Kernel module with an at_fork method for installing at_fork
# handlers. 
#
# NOTE: at_fork handlers are executed in the thread that does the forking and
# that survives the process fork. 
#
# Usage: 
# 
#   at_fork do 
#     # Do something on fork (in the forking process)
#   end
#   at_fork(:child) { ... }  # do something in the forked process 
#   at_fork(:parent) { ... } # do something in the forking process
# 
module Kernel
  # Child at_fork handlers
  #
  def self.at_fork_child
    @at_fork_child ||= []
  end
  
  # Parent at_fork handlers
  #
  def self.at_fork_parent
    @at_fork_parent ||= []
  end
  
  def at_fork(type=:parent,&block)
    raise ArgumentError, "Must provide a handler block." unless block
    
    handler_array = (type == :child) ? 
      Kernel.at_fork_child : Kernel.at_fork_parent
      
    handler_array << block
  end
  
  def fork_with_at_fork(&block)
    Kernel.at_fork_parent.each(&:call)
    
    fork_without_at_fork do
      # From this point on, operation is single threaded.
      
      Kernel.at_fork_child.each(&:call)
      
      Kernel.at_fork_parent.replace([])
      Kernel.at_fork_child.replace([])
      
      block.call
    end
  end
  alias fork_without_at_fork  fork
  alias fork                  fork_with_at_fork
end