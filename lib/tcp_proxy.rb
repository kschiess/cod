class TCPProxy
  attr_reader :connections
  
  def initialize(host, from_port, to_port)
    @ins  = TCPServer.new(host, from_port)

    @host = host
    @from_port, @to_port = from_port, to_port

    # Active connections and mutex to protect access to it.
    @connections = []
    @connections_m = Mutex.new
    
    # Are we currently accepting new connections?
    @accept_new = true
    
    @thread = Thread.start(&method(:thread_main))
  end
  
  def close
    @shutdown = true
    
    @thread.join
    @thread = nil
    
    # Since the thread is stopped now, we can be sure no new connections are
    # accepted. This is why we access the collection without locking.
    @connections.each do |connection|
      connection.close
    end
    @ins.close
  end
  
  def block
    @accept_new = false
  end
  def allow
    @accept_new = true
  end
  
  def drop_all
    # Copy the connections and then empty the collection
    connections = @connections_m.synchronize {
      @connections.tap { 
        @connections = [] } }
    
    connections.each do |conn|
      conn.close
    end
  end
  
  # Inside the background thread ----------------------------------------
  
  def thread_main
    loop do
      accept_connections if @accept_new
      
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
      @m = Mutex.new
      @in_sock, @out_sock = in_sock, out_sock
    end
    
    def close
      @m.synchronize {
        @in_sock.close; @in_sock = nil
        @out_sock.close; @out_sock = nil }
    end

    def pump_synchronized(n=10)
      @m.synchronize {
        return unless @in_sock && @out_sock
        pump(n) }
    end
    
    def pump(n)
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
      
      @connections_m.synchronize {
        @connections << Connection.new(in_sock, out_sock) }
    end
  rescue Errno::EAGAIN
    # No more connections pending, stop accepting new connections
  end
  
  def forward_data
    connections = @connections_m.synchronize { @connections.dup }
    connections.each do |conn|
      conn.pump_synchronized
    end
  end
end