$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

begin
  pipe ||= Cod.beanstalk('pingpong', 'localhost:11300')

  loop do
    pipe.put Time.now
    sleep 1
  end
rescue Cod::ConnectionLost
  pipe.close
  pipe = nil
  retry
end