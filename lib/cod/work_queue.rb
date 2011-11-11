

module Cod
  # Describes a queue that stores work items given through #schedule and works
  # through those items in order if #predicate is true. 
  #
  # Synopsis: 
  #   queue = WorkQueue.new
  #   queue.predicate { true }
  #   queue.schedule { 
  #     # some work
  #   }
  # 
  #   # Will try to work through items right now. 
  #   queue.try_work
  # 
  #   # Will cleanly shutdown background threads, but not finish work. 
  #   queue.shutdown
  # 
  class WorkQueue
    def initialize
      # NOTE: This is an array that is protected by careful coding, rather
      # than a mutex. Queue would be right, but Rubys GIL will interfere with
      # that producing more deadlocks than I would like.
      @queue = Array.new
      
      @thread = Thread.start(&method(:thread))
    end
    def predicate
    end
    def schedule(&work)
      @queue << work
    end
    def shutdown
      @shutdown_requested = true
      @thread.join
    end
    def size
      @queue.size
    end
  private
    def thread
      Thread.current.abort_on_exception = true
      
      loop do
        sleep 0.1
        return if @shutdown_requested
      end
    end
  end
end