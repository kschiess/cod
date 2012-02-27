# This example spawns a small worker process that will provide a simple
# service to its parent process. This is just one way of structuring this; the
# important part here is the client/service code. 

$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'

service_channel = Cod.pipe
answer_channel = Cod.pipe

child_pid = fork do
  service = service_channel.service()
  service.one { |call| 
    puts "Service got called with #{call.inspect}" 
    time = Time.now
    puts "Answering with current time: #{time}"
    time }
end

client = service_channel.client(answer_channel)
puts "Calling service..."
answer = client.call('42')

puts "Service answered with #{answer}."

Process.wait(child_pid)