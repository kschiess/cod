$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

announce = Cod.pipe
directory = Cod::Directory.new(announce)

pipes = []
pids = ['foo.bar', /^foo\..+/].map { |match_expr| 
  pipes << pipe = Cod.pipe  # store in pipes as well to prevent GC
  fork do
    puts "Spawned child: #{Process.pid}"
    topic = Cod::Topic.new(match_expr, announce, pipe)
    
    sleep 0.1
    loop do
      message = topic.get
      puts "#{Process.pid}: received #{message.inspect}."
      
      break if message == :shutdown
    end
  end }
  
directory.publish 'foo.bar', 'Hi everyone!'
directory.publish 'foo.baz', 'Hi you!'

directory.publish 'foo.bar', :shutdown  
Process.waitall
