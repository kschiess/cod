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
        # Check if there are pending connects
        accept_new_connections

        # shuffle the socket list around, so we don't always read from the
        # same client.
        socket_list = round_robin(@client_sockets)

        # select for readiness
        rr, rw, re = IO.select(socket_list, nil, nil, 0.1)
        next unless rr
        
        rr.each do |io|
          if io.eof?
            @client_sockets.delete(io)
            io.close
          else
            consume_pending io, opts
          end
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