$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

announce = Cod.pipe
directory = Cod::Directory.new(announce)

pipes = []
pids = ['foo.bar', /^foo\..+/].map { |match_expr| 
  # Creates a communication channel that both the parent and the child know
  # about. After the fork, they will own unique ends to that channel. 
  pipes << pipe = Cod.pipe  # store in pipes as well to prevent GC
  
  # Create a child that will receive messages that match match_expr.
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
  
directory.publish 'foo.bar', 'Hi everyone!'   # to both childs
directory.publish 'foo.baz', 'Hi you!'        # only second child matches this
directory.publish 'no.one', 'echo?'           # no one matches this

directory.publish 'foo.bar', :shutdown        # shutdown children in orderly fashion
Process.waitall
