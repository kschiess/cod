$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

queue = Cod.tcp('localhost:12345')

queue.put [:join, queue]

class CallCounter
  attr_reader :n
  def initialize
    @n = 0
    @last_lap = [0, Time.now]
  end
  def inc
    @n += 1
  end
  def calls_per_sec
    ln, ll = @last_lap
    @last_lap = [@n, Time.now]
    
    (@n - ln) / (Time.now - ll)
  end
end

cc = CallCounter.new
loop do
  wi = queue.get
  
  cc.inc
  puts cc.calls_per_sec if cc.n%100==0 
end