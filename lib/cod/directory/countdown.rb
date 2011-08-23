class Cod::Directory
  class Countdown
    def initialize(now = Time.now)
      @run_time = 30 * 60 # 30 minutes
      start(now)
    end
    
    def elapsed?(now = Time.now)
      if running?
        return (now - @started_at) > @run_time
      else
        return (@stopped_at - @started_at) > @run_time
      end
    end
    
    def running?
      !@stopped_at
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