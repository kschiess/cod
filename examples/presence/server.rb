
$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'


present = {}
server = Cod.tcpserver('localhost:12345')

loop do
  # Process connection requests
  while server.waiting?
    connection, attributes = server.get
    
    present[connection] = attributes
  end

  # Check if all connections are alive
  remove = []
  present.each do |conn, attrs|
    if conn.connected?
      puts "Alive: #{attrs.inspect}"
    else
      puts "Dead: #{attrs.inspect}"
      remove << conn
    end
  end
  
  remove.each { |conn| present.delete(conn) }
  sleep 1
end
