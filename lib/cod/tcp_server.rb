module Cod
  class TcpServer
    def initialize(bind_to)
      @socket = TCPServer.new(*bind_to.split(':'))
      @client_sockets = []
      @round_robin_index = 0
      @messages = Array.new
      @serializer = SimpleSerializer.new
    end
    
    # Receives one object from the channel. 
    #
    # Example: 
    #   channel.get # => object
    #   
    def get
      loop do
        p [:get_loop, @client_sockets.size]
        # Check if there are pending connects
        accept_new_connections

        # shuffle the socket list around, so we don't always read from the
        # same client.
        socket_list = round_robin(@client_sockets)

        # select for readiness
        rr, rw, re = IO.select(socket_list, nil, nil, 0.1)
        next unless rr
        
        rr.each do |io|
          consume_pending io
        end
        
        return @messages.shift unless @messages.empty?
      end
    end
    
    def consume_pending(io)
      buffer = io.read_nonblock(10*1024)
      tracked_buffer = StringIO.new(bufffer)
      while !tracked_buffer.eof?
        @messages << serializer.de(tracked_buffer)
      end
    end
    
    def round_robin(list)
      @round_robin_index += 1
      if @round_robin_index >= list.size
        @round_robin_index = 0
      end
      
      # Create a duplicate of list that has its elements rotated by
      # @round_robin_index
      list = list.dup
      list = list + list.shift(@round_robin_index)
    end
    
    def accept_new_connections
      loop do
        @client_sockets << @socket.accept_nonblock
      end
    rescue Errno::EAGAIN
      # This means that there are no sockets to accept. Continue.
    end
  end
end