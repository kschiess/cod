$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

channels = Struct.new(:directory, :answers).new(
  Cod.beanstalk('localhost:11300', 'directory'), 
  Cod.beanstalk('localhost:11300', 'directory.'+Cod.uuid))
  
topic = Cod::Topic.new('', channels.directory, channels.answers)

loop do
  puts topic.get
end

