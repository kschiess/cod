class Monitor
  def initialize
    @work = Array.new
    Thread.start(&method(:run))
  end

  def work(&block)
    @work << block
    
    try_work
  end
  
  def work_if(&block)
    @predicate = block
  end
  
  def try_work
    if @predicate[]
      p :pred_true
      until @work.empty?
        w = @work.shift
        w[]
      end
    end
  end
  
  def run
    loop do
      try_work
      
      sleep 1
    end
  end
end

def connection?
  rand() > 0.7
end

def send
  p :send
end

m = Monitor.new
m.work_if { connection? }

10.times do
  m.work do
    send
    sleep 0.1
  end
end

sleep 2

  
