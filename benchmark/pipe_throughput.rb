require 'thread'

$:.unshift File.dirname(__FILE__)+"/../lib"
require 'cod'

class PipeThroughput
  RUNTIME = 5
  
  def self.run(n, queue)
    new(queue).run(n)
  end
  
  attr_reader :queue
  def initialize(queue)
    @queue = queue
  end
  
  def run(n)
    Thread.abort_on_exception = true
    
    # One thread reads, N Threads produce
    reader = Thread.new(&method(:reader))
    writers = n.times.map { 
      Thread.new(&method(:writer)) }
      
    # start all threads and run for RUNTIME seconds
    # reader.run
    # writers.each { |t| t.run }
    
    start_time = Time.now
    sleep 1 while Time.now - start_time < RUNTIME

    writers.each { |t| t.kill }
    reader.kill
    
    stop_time = Time.now
    seconds = stop_time - start_time
    
    write_count = writers.map { |t| t[:written] }.inject(0, &:+)
    printf "read: %10d, wrote: %10d (%10d wps)\n", @read_count, write_count, 
     write_count / seconds
  end
  
  def reader
    q = queue
    q = queue.dup if queue.kind_of? Cod::Channel::Pipe
    
    @read_count = 0
    loop do
      q.get
      @read_count += 1
    end
  end
  
  def writer
    q = queue
    q = queue.dup if queue.kind_of? Cod::Channel::Pipe
    
    Thread.current[:written] = 0
    loop do
      q.put :test
      Thread.current[:written] += 1
    end
  end
end

def queue
  Queue.new.tap { |q| 
    class <<q
      alias get pop
      alias put push
    end }
end

(1..8).each do |n|
  print "#{n} threads, queue: "
  PipeThroughput.run(n, queue)
end
(1..8).each do |n|
  print "#{n} threads, pipe:  "
  PipeThroughput.run(n, Cod.pipe)
end
