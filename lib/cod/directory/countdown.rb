class Cod::Directory
  class Countdown
    def initialize(run_time=30*60, now = Time.now)
      @run_time = run_time
      start(now); stop
    end
    
    def elapsed?(now = Time.now)
      if running?
        return (now - @started_at) > @run_time
      else
        return (@stopped_at - @started_at) > @run_time
      end
    end
    
    def running?
      @started_at && !@stopped_at
    end
    
    def start(now = Time.now)
      @started_at = now
      @stopped_at = nil
    end
    
    def stop(now = Time.now)
      @stopped_at = now
    end
  end
end