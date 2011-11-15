

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

    def try_work
      # NOTE if predicate is nil or not set, no work will be accomplished. 
      # This is the way I need it. 
      while !@queue.empty? && @predicate && @predicate.call
        wi = @queue.shift
        wi.call
      end
    end
    
    # Before any kind of work is attempted, this predicate must evaluate to 
    # true. It is tested repeatedly. 
    #
    # Example: 
    #   work_queue.predicate { connection.established? }
    #
    def predicate(&predicate)
      @predicate = predicate
    end

    # Schedules a piece of work. 
    # Example: 
    #   work_queue.schedule { a_piece_of_work }
    #
    def schedule(&work)
      @queue << work
    end

    # Shuts down the queue properly, without waiting for work to be completed.
    #
    def shutdown
      @shutdown_requested = true
      @thread.join
    end
    
    # Returns the size of the queue. 
    #
    def size
      @queue.size
    end
  private
    def thread
      Thread.current.abort_on_exception = true
      
      loop do
        Thread.pass
        
        try_work
        
        return if @shutdown_requested
      end
    end
  end
end