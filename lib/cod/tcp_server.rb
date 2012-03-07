require 'socket'

module Cod       
  # A tcp server channel. Messages are read from any of the connected sockets
  # in a round robin fashion. 
  #
  # Synopsis: 
  #   server = Cod.tcp_server('localhost:12345') 
  #   server.get  # 'a message'
  #   msg, chan = server.get_ext
  #
  # There is no implementation of #put that would broadcast back to all
  # connected sockets, this is up to you to implement. Instead, you can use
  # one of two ways to obtain a channel for talking back to a specific client:
  # 
  # Using #get_ext:
  #   msg, chan = server.get_ext 
  #
  # chan is a two way connected channel to the specific client that has opened 
  # its communication with msg. 
  #
  # Using plain #get: 
  #   # on the client: 
  #   client.put [client, :msg]
  #   # on the server
  #   chan, msg = server.get
  #
  # This means that you can transmit the client channel through the connection 
  # as part of the message you send. 
  # 
  class TcpServer
    def initialize(bind_to, serializer)
      @socket = TCPServer.new(*bind_to.split(':'))
      @client_sockets = []
      @round_robin_index = 0
      @messages = Array.new
      @serializer = serializer
    end
    
    # Receives one object from the channel. This will receive one message from
    # one of the connected clients in a round-robin fashion. 
    #
    # @example
    #   channel.get # => object
    #
    # @param opts [Hash] 
    # @return [Object] message sent by one of the clients
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
    # @example Answering to the client that sent a specific message
    #   msg, chan = server.get_ext
    #   chan.put :answer
    #
    # @param opts [Hash]
    # @return [Array<Object, TcpClient>] tuple of the message that was sent 
    #   a channel back to the client that sent the message
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
    
    # Returns the number of clients that are connected to this server
    # currently.
    # 
    def connections
      @client_sockets.size
    end

    # --------------------------------------------------------- service/client
    
    def service
      Service.new(self)
    end
    # NOTE: It is really more convenient to just construct a Cod.tcp_client 
    # and ask that for a client object. In the case of TCP, this is enough. 
    #
    def client(answers_to)
      Service::Client.new(answers_to, answers_to)
    end

  private
    def _get(opts)
      loop do
        # Return a buffered message if there is one left.
        return @messages.shift unless @messages.empty?

        # Shuffle the socket list around, so we don't always read from the
        # same client first.
        socket_list = round_robin(@client_sockets)
        
        # Append the server socket to be able to react to new connections
        # that are made.
        socket_list << @socket
      
        # Sleep until either a new connection is made or data is available on 
        # one of the old connections. 
        rr, _, _ = IO.select(socket_list, nil, nil)
        next unless rr
        
        # Accept new connections
        if rr.include?(@socket)
          accept_new_connections
          rr.delete(@socket)
        end
        
        handle_socket_events(rr, opts)
      end
    end
    
    def handle_socket_events(sockets, opts)
      sockets.each do |io|
        if io.eof?
          @client_sockets.delete(io)
          io.close
        else
          consume_pending io, opts
        end
      end
    end
  
    def consume_pending(io, opts)
      until io.eof?
        @messages << [
          deserialize(io), 
          io]
          
        # More messages from this socket? 
        return unless IO.select([io], nil, nil, 0.0001)
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