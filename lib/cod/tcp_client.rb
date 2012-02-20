require 'cod/work_queue'

module Cod
  # Acts as a channel that connects to a tcp listening socket on the other
  # end. 
  #
  # Connection negotiation has three phases, as follows: 
  # 1) Connection is establishing. Sent messages are buffered and really sent
  #    down the wire once the connection stands. Reading from the channel
  #    will block the client forever.
  #
  # 2) Connection is established: Sending and receiving are immediate and 
  #    no buffering is done. 
  #
  # 3) Connection is down because of an interruption or exception. Sending and
  #    receiving messages no longer works, instead a ConnectionLost error is
  #    raised. 
  #
  class TcpClient < Channel
    # Constructs a tcp client channel. destination may either be a socket, 
    # in which case phase 1) of connection negotiation is skipped, or a string
    # that contains an 'address:port' part. 
    #
    def initialize(destination, serializer)
      @serializer = serializer
      @destination = destination

      # TcpClient handles two cases: Construction via an url (destination is a
      # string) and construction via a connection that has been
      # preestablished (destination is a socket):
      if destination.respond_to?(:read)
        # destination seems to be a socket, wrap it with Connection
        @connection = Connection.new(destination)
      else
        @connection = RobustConnection.new(destination)
      end

      @work_queue = WorkQueue.new

      # The predicate for allowing sends: Is the connection up?
      @work_queue.predicate {
        # NOTE This will not be called unless we have some messages to send,
        # so no useless connections are made
        @connection.try_connect
        @connection.established?
      }
    end
    
    # Closes all underlying connections. You should only call this if you
    # don't want to use the channel again, since it will also stop
    # reconnection attempts. 
    #
    def close
      @work_queue.shutdown
      @connection.close
    end

    # Sends an object to the other end of the channel, if it is connected. 
    # If it is not connected, objects sent will queue up and once the internal
    # storage reaches the high watermark, they will be dropped silently. 
    #
    # Example: 
    #   channel.put :object
    #   # Really, any Ruby object that the current serializer can turn into 
    #   # a string!
    #
    def put(obj)
      # TODO high watermark check
      # NOTE: predicate will call #try_connect
      @work_queue.schedule {
        send(obj)
      }
      
      @work_queue.try_work
    end
    
    # Receives a message. opts may contain various options, see below. 
    # Options include: 
    #
    def get(opts={})
      @connection.try_connect
      @connection.read(@serializer)
    end

    # --------------------------------------------------------- service/client
    
    def service
      fail "A tcp client cannot be a service."
    end
    def client
      # NOTE: Normally, it doesn't make sense to ask the client channel for
      # something for a service connection, since the service needs to know
      # where to send requests in addition to knowing where to receive
      # answers. In the case of sockets, this is different: The service will
      # send its answers back the same way it got the requests from, so this
      # is really ok:
      #
      Service::Client.new(self, self)
    end

    # ---------------------------------------------------------- serialization 
    
    # A small structure that is constructed for a serialized tcp client on 
    # the other end (the deserializing end). What the deserializing code does
    # with this is his problem. 
    #
    OtherEnd = Struct.new(:destination) # :nodoc:

    def _dump(level) # :nodoc:
      @destination
    end
    def self._load(params) # :nodoc:
      # Instead of a tcp client (no way to construct one at this point), we'll
      # insert a kind of marker in the object stream that will be replaced 
      # with a valid client later on. (hopefully)
      OtherEnd.new(params)
    end
  private
    def send(msg)
      @connection.write(
        @serializer.en(msg))
    end

    # A connection that can be down. This allows elegant handling of
    # reconnecting and delaying connections. 
    #
    # Synopsis: 
    #   connection = RobustConnection.new('foo:123')
    #   connection.try_connect
    #   connection.write('buffer')
    #   connection.established? # => false
    #   connection.close
    #
    class RobustConnection # :nodoc: 
      def initialize(destination)
        @destination = destination
        @socket = nil
      end
      
      attr_reader :destination
      attr_reader :socket
      
      # Returns true if a connection is currently running. 
      #
      def established?
        !! @socket
      end
      
      # Attempt to establish a connection. If there is already a connection
      # and it still seems sound, does nothing. 
      #
      def try_connect
        return if established?
        
        @socket = TCPSocket.new(*destination.split(':'))
      rescue Errno::ECONNREFUSED
        # No one listening? Well.. too bad.
        @socket = nil
      end
      
      # Writes a buffer to the connection if it is established. Otherwise
      # fails silently. 
      #
      def write(buffer)
        if @socket
          @socket.write(buffer)
        end
      end
      
      # Reads one message from the socket if possible. 
      #
      def read(serializer)
        return serializer.de(@socket) if @socket
        
        # assert: @socket is still nil, because no connection could be made. 
        # Try to make one
        loop do
          try_connect
          return serializer.de(@socket) if @socket
          sleep 0.01
        end
      end

      # Closes the connection and stops reconnection. 
      #
      def close
        @socket.close if @socket
        @socket = nil
      end
    end
    
    # Holds a connection that we don't create and therefore don't own. This
    # is the case where a channel is created to communicate back to one of
    # the TcpServers clients: the tcp server manages the back channels, so
    # the created channel is lent its socket only.
    #
    class Connection # :nodoc:
      def initialize(socket)
        @socket = socket.dup
      end
      attr_reader :socket
      def try_connect
      end
      def established?
        true
      end
      def read(serializer)
        serializer.de(@socket)
      end
      def write(buffer)
        @socket.write(buffer)
      end
      def close
        @socket.close
      end
    end
  end
end