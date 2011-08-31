$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'

class Queue
  def initialize(url)
    @url = url
    connect
  end
  
  def connect
    @clients = []
    @server = Cod.tcpserver(@url)
  end
  
  def run
    loop do
      handle_commands
      
      check_connections
    end
  end
  
  def handle_commands
    while @server.waiting?
      cmd, *rest = @server.get
      
      dispatch_command cmd, rest
    end
  end
  
  def dispatch_command(cmd, rest)
    self.send("cmd_#{cmd}", *rest)
  end
  
  def cmd_join(connection)
    puts "Join at #{Time.now}."
    @clients << connection
  end
  
  def cmd_work_item
    @clients.each do |client|
      client.put :work_item
    end
  end
  
  def check_connections
    @clients.keep_if { |client| client.connected? }
  end
end

Queue.new('localhost:12345').run