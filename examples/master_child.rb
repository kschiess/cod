$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

pipe = Cod::Channel::Pipe.new

child_pid = fork do
  pipe.put 'test'
  pipe.put Process.pid
end

begin
  puts pipe.get
  puts pipe.get
ensure
  Process.wait(child_pid)
end
