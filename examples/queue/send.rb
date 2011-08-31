$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

queue = Cod.tcp('localhost:12345')

n = Integer(ARGV.first)
n.times do
  queue.put :work_item
end