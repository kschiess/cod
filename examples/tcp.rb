$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
$:.unshift File.expand_path(File.dirname(__FILE__))
require 'cod'

require 'example_scaffold'

server {
  channel = Cod.tcp_server('127.0.0.1:5454')
  
  client = channel.get
  client.put 'heiho from server'
}

client {
  channel = Cod.tcp('127.0.0.1:5454')
  
  channel.put channel
  puts channel.get
}

run