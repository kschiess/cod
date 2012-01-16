

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
  class WorkQueue # :nodoc:
    def initialize
      # NOTE: This is an array that is protected by careful coding, rather
      # than a mutex. Queue would be right, but Rubys GIL will interfere with
      # that producing more deadlocks than I would like.
      @queue = Array.new
      
      @try_work_exclusive_section = ExclusiveSection.new

      @thread = Thread.start(&method(:thread_main))
    end
    
    # The internal thread that is used to work on scheduled items in the
    # background.
    attr_reader :thread

    def try_work
      @try_work_exclusive_section.enter {
        # NOTE if predicate is nil or not set, no work will be accomplished. 
        # This is the way I need it. 
        while !@queue.empty? && @predicate && @predicate.call
          wi = @queue.shift
          wi.call
        end
      }
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

    def clear_thread_semaphore
      @one_turn = false
    end
    def thread_semaphore_set?
      @one_turn
    end
  private
    def thread_main
      Thread.current.abort_on_exception = true
      
      loop do
        sleep 0.001

        try_work

        # Signal the outside world that we've been around this loop once.
        # See #clear_thread_semaphore and #thread_semaphore_set?
        @one_turn = true
        
        return if @shutdown_requested
      end
    end
  end
  
  # A section of code that is entered only once. Instead of blocking threads
  # that are waiting to enter, it just returns nil.
  #
  class ExclusiveSection # :nodoc:
    def initialize
      @mutex = Mutex.new
      @threads_in_block = 0
    end
    
    # If no one is in the block given to #enter currently, this will yield
    # to the block. If one thread is already executing that block, it will
    # return nil.
    #
    def enter
      @mutex.synchronize { 
        return if @threads_in_block > 0
        @threads_in_block += 1 }
      begin
        yield
      ensure
        fail "Assert fails, #{@threads_in_block} threads in block" \
          if @threads_in_block != 1
        @mutex.synchronize { 
          @threads_in_block -= 1 }
      end
    end
  end
end