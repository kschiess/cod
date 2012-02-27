$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

pipe = Cod.beanstalk('localhost:11300', "pingpong")

loop do
  puts "Received: "+pipe.get.inspect
end
  