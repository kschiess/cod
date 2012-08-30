$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

pipe = Cod.bidir_pipe

child_pid = fork do
  pipe.swap!
  pipe.put 'test'
  pipe.put Process.pid
  command = pipe.get 
  p command
end

begin
  p pipe.get
  p pipe.get
  pipe.put :foobar
ensure
  Process.wait(child_pid)
end
