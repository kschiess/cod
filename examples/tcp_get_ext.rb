$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
$:.unshift File.expand_path(File.dirname(__FILE__))
require 'cod'
require 'example_scaffold'

2.times do 
  client {
    chan = Cod.tcp('localhost:1234')
    chan.put :get_client_id
    p [:client_id, chan.get]
  }
end

server {
  server = Cod.tcp_server('localhost:1234')
  client_id = 0
  
  loop do
    msg, chan = server.get_ext

    p [:incoming, msg, chan.object_id.to_s(16)]
    begin
      case msg 
        when :get_client_id
          client_id += 1
          chan.put client_id
      end
          
    ensure
      # Closes connections after one request.
      chan.close 
    end
    
    break if client_id >= 2
  end
}

run