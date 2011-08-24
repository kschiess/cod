$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

channels = Struct.new(:directory).new(
  Cod.beanstalk('localhost:11300', 'directory'))
  
directory = Cod::Directory.new(channels.directory)

loop do
  directory.publish '', Time.now
  sleep 1
end

