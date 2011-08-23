
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
    @master = Cod.pipe
    
    @ready = false
    @pid = fork do
      @master, @child = @master.dup, @child.dup

      proxy_main
    end
  end
  
  def kill
    Process.kill('TERM', pid)
    Process.wait(pid)
  end
  
  def conn_count
    child.put :conn_count
    master.get
  end
  
  def kill_all_connections
    child.put :kill_all if child
    master.get
  end
  
  def ready?
    if not @ready && master.waiting?
      @ready = true
      master.get
    end
    @ready
  end
  
  # ------------------------------------------------ executed in child process 
  def proxy_main
    master.put :ready
    
    @proxy_server = TCPServer.new(*@from)
    @proxied_sockets = {}
    
    loop do
      accept_connections
      # p [:accept, proxied_sockets.size]
      
      handle_commands
      
      ready, _, error = IO.select(
        proxied_sockets.keys, 
        nil, 
        proxied_sockets.keys, 
        0.01)
      
      next unless ready
      relay_pending ready
    end
  end
  
  def handle_commands
    if child.waiting?
      cmd=child.get
      # p [:cmd, cmd]
      case cmd
        when :kill_all
          proxied_sockets.each do |i,o|
            i.close
            o.close
          end
          @proxied_sockets = {}
          p :killed
          master.put :done
        when :conn_count
          master.put proxied_sockets.size
      else
        p [:unknown_command, cmd]
      end
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
      begin
        buffer = socket.read_nonblock(1024)
        # p [:relay, buffer.size]
        proxied_sockets[socket].write(buffer)
      rescue EOFError
        # This means one or the other socket is already closed. 
        # DO NOTHING
      end
    end
  end
end