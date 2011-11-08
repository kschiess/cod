
# This is a design exploration: How to create a structure that supports
# executing a small bit of work right now or later, until it is completed. 

require 'thread'

Thread.current.abort_on_exception = true

class Work
  def do
    p [:do_work, self]
  end
end

class ExclusiveBlock
  def initialize
    @enter_count = 0
    @enter_count_m = Mutex.new
  end
  
  def enter
    @enter_count_m.synchronize { 
      return if @enter_count > 0
      @enter_count += 1
    }
    yield
    @enter_count_m.synchronize {
      @enter_count -= 1
    }
  end
end

class BackgroundWork
  def initialize
    @queue = Array.new
    @exclusive = ExclusiveBlock.new
    @thread = Thread.start(&method(:thread_run))
  end
  
  def enqueue(work_item)
    p [:enqueue, work_item]
    @queue << work_item
    
    try_complete
  end
  
  def can_start?
    rand() < 0.5
  end
    
  def try_complete
    @exclusive.enter do
      return if @queue.empty?
      
      if can_start?
        while work = @queue.shift
          work.do
        end
      end
    end
  end
  
  def thread_run
    Thread.current.abort_on_exception = true

    loop do
      p [:thread_spin, @queue.size]

      sleep 0.1 
      return if @shutdown_requested
      
      try_complete
    end
  end
  
  def shutdown
    @shutdown_requested = true
  end
end

bw = BackgroundWork.new
bw.enqueue(Work.new)
bw.enqueue(Work.new)
bw.enqueue(Work.new)

p [:do_other_stuff, Time.now.to_i]
sleep 1
p [:done, Time.now.to_i]

# Shutdown resources, don't complete
p :shutdown
bw.shutdown
