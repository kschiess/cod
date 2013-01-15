require 'socket'

module Cod
  
  # Abstract base class for all kinds of socket based servers. Useful for all
  # types of channels that know an #accept. 
  #
  class SocketServer
    attr_reader :socket
    
    def initialize(serializer, socket)
      @socket = socket
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
        produce_back_channel(socket)]
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
      @client_sockets + [@socket]
    end
    
    # Returns the number of clients that are connected to this server
    # currently.
    # 
    def connections
      @client_sockets.size
    end

    # ------------------------------------------------------- connection owner
    
    # Notifies the TcpServer that one of its connections needs to be closed.
    # This can be triggered by using #get_ext to obtain a handle to
    # connections and then calling #close on that connection. 
    #
    # @param socket [TCPSocket] the socket that needs to be closed @return
    # [void]
    #
    def request_close(socket)
      @client_sockets.delete(socket)
      socket.close
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
        socket_list << socket
      
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
    
    # Hooks deserialisation (if the programmer provided for this) and calls
    # #deserialize_special for each object in the object stream. This allows
    # construction of back channels from replacement tokens, for example.
    #
    def deserialize(io)
      @serializer.de(io) { |obj| deserialize_special(io, obj) }
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