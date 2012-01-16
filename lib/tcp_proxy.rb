class TCPProxy
  attr_reader :connections
  
  def initialize(host, from_port, to_port)
    @ins  = TCPServer.new(host, from_port)

    @host = host
    @from_port, @to_port = from_port, to_port
    @connections = []
    
    @thread = Thread.start(&method(:thread_main))
  end
  
  def close
    @shutdown = true
    
    p [:shutdown]
    @thread.join
    p [:joined]
    @thread = nil
  end
  
  # Inside the background thread ----------------------------------------
  
  def thread_main
    loop do
      accept_connections
      
      forward_data
      
      break if @shutdown
    end
  rescue Exception => ex
    p [:uncaught, ex]
    ex.backtrace.each do |line|
      puts line
    end
    raise
  end

  class Connection
    def initialize(in_sock, out_sock)
      @in_sock, @out_sock = in_sock, out_sock
    end
    
    def pump(n=10)
      while n>0
        available_sockets = [@in_sock, @out_sock]
        ready_sockets, (*) = IO.select(available_sockets, nil, nil, 0)

        break unless ready_sockets && !ready_sockets.empty?
        
        ready_sockets.each do |socket|
          buf = socket.read_nonblock(16*1024)
          
          if socket == @in_sock
            puts "--> #{buf.size}"
            @out_sock.write(buf)
          else
            puts "<-- #{buf.size}"
            @in_sock.write(buf)
          end
        end

        n -= 1
      end
    rescue Errno::EAGAIN
      # Read would block, attempt later
    end
  end

  def accept_connections
    loop do
      in_sock = @ins.accept_nonblock
      out_sock = TCPSocket.new(@host, @to_port)
      p [:accepted]
      
      @connections << Connection.new(in_sock, out_sock)
    end
  rescue Errno::EAGAIN
    # No more connections pending, stop accepting new connections
  end
  
  def forward_data
    @connections.each do |conn|
      conn.pump
    end
  end
end