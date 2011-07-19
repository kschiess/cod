
# A TCPServer that proxies from_url to to_url. Allows to interrupt the
# connection and reconnect it, simulating various connection related error
# situations. 
#
class DebugProxy
  include Cod::Channel::TCP
  
  attr_reader :proxied_sockets
  attr_reader :proxy_server
  attr_reader :pid
  attr_reader :child
  attr_reader :master
  
  def initialize(from_url, to_url)
    @from = split_uri(from_url)
    @to   = split_uri(to_url)
    
    spawn_proxy
  end
  
  def spawn_proxy
    @child = Cod.pipe
    @pid = fork do
      @master = @child.dup
      @child = nil

      proxy_main
    end
  end
  
  def kill
    Process.kill('TERM', pid)
    Process.wait(pid)
  end
  
  def kill_all_connections
    child.put :kill_all if child
  end
  
  # ------------------------------------------------ executed in child process 
  def proxy_main
    @proxy_server = TCPServer.new(*@from)
    @proxied_sockets = {}
    
    loop do
      accept_connections
      p [:accept, proxied_sockets.size]
      
      ready, _, error = IO.select(
        proxied_sockets.keys, 
        nil, 
        proxied_sockets.keys, 
        0.1)
      
      while master.waiting?
        case cmd=master.get
          when :kill_all
            # TODO
        else
          p [:unknown_command, cmd]
        end
      end
                
      next unless ready
      relay_pending ready
    end
  end
  
  def accept_connections
    begin
      socket = proxy_server.accept_nonblock
      proxied_sockets[socket] = TCPSocket.new(*@to)
    rescue Errno::EAGAIN
      # IGNORE: no connection is pending
    end
  end
  
  def relay_pending(sockets)
    sockets.each do |socket|
      buffer = socket.read_nonblock(1024)
      p [:relay, buffer.size]
      proxied_sockets[socket].write(buffer)
    end
  end
end