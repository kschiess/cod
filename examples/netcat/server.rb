$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

fork do
  server = Cod.tcp_server('localhost:12345')

  request, channel = server.get_ext
  case request
    when :get_time
      channel.put Time.now
  else 
    fail
  end
end

fork do
  sleep 1
  process = Cod.process('nc localhost 12345')
  channel = process.channel
  
  channel.put :get_time
  puts channel.get
end

Process.waitall