$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

pipe = Cod.pipe

child_pid = fork do
  pipe.put 'test'
  pipe.put Process.pid
end

begin
  p pipe.get
  p pipe.get
ensure
  Process.wait(child_pid)
end
