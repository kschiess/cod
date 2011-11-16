require 'cod/work_queue'

module Cod
  # Acts as a channel that connects to a tcp listening socket on the other
  # end. 
  #
  class TcpClient
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
        if @socket
          return serializer.de(@socket)
        end
        
        raise EOFError  # or so
      end

      # Closes the connection and stops reconnection. 
      #
      def close
        @socket.close if @socket
        @socket = nil
      end
    end
    
    class Connection
      def initialize(socket)
        @socket = socket
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
    end
    
    def initialize(destination, serializer)
      @serializer = serializer

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
    # don't want to use the channel again, since it will also stop reconnection
    # attempts. 
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
      @work_queue.schedule {
        send(obj)
      }
      
      @work_queue.try_work
    end
    
    # Receives a message. opts may contain various options, see below. 
    # Options include: 
    #
    def get(opts={})
      @connection.read(@serializer)
    end

    class OtherEnd
    end

    def _dump(level)
      ""  # TODO replace with something that allows end-to-end id
    end
    def self._load(params)
      # Instead of a tcp client (no way to construct one at this point), we'll
      # insert a kind of marker in the object stream that will be replaced 
      # with a valid client later on. (hopefully)
      OtherEnd.new
    end
  private
    def send(msg)
      @connection.write(
        @serializer.en(msg))
    end
  end
end