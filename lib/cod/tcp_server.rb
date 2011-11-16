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
    def get(opts={})
      msg, socket = _get(opts)
      return msg
    end
    
    # Receives one object from the channel. Returns a tuple of
    # <message,channel> where channel is a tcp channel that links back to the
    # client that sent message.
    #
    # Using this method, the server can communicate back to its clients
    # individually instead of collectively. 
    #
    # Example: 
    #   msg, chan = server.get_ext
    #   chan.put :answer
    def get_ext(opts={})
      msg, socket = _get(opts)
      return [
        msg, 
        TcpClient.new(socket, @serializer)]
    end
    
    # Closes the channel. 
    #
    def close
      @socket.close
      @client_sockets.each { |io| io.close }
    end

    # Returns an array of IOs that Cod.select should select on. 
    #
    def to_read_fds
      @client_sockets
    end

  private
    def _get(opts)
      loop do
        # Check if there are pending connects
        accept_new_connections

        # shuffle the socket list around, so we don't always read from the
        # same client.
        socket_list = round_robin(@client_sockets)

        # select for readiness
        rr, rw, re = IO.select(socket_list, nil, nil, 0.1)
        next unless rr
        
        rr.each do |io|
          consume_pending io, opts
        end
        
        return @messages.shift unless @messages.empty?
      end
    end
  
    def consume_pending(io, opts)
      until io.eof?
        @messages << [
          deserialize(io), 
          io]
          
        # More messages from this socket? 
        return unless IO.select([io], nil, nil, 0.01)
      end
    end
    
    def deserialize(io)
      @serializer.de(io) { |obj|
        obj.kind_of?(TcpClient::OtherEnd) ? 
          TcpClient.new(io, @serializer) :
          obj
      }
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