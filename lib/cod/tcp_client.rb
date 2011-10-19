require 'thread'

module Cod
  class TcpClient
    class Connection
      def initialize(destination)
        @destination = destination
        @socket = nil
      end
      
      attr_reader :destination
      
      # Returns true if a connection is currently running. 
      #
      def established?
        !! @socket
      end
      
      # Attempt to establish a connection. If there is already a connection
      # and it still seems sound, does nothing. 
      #
      def try_connect
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
    end
    class BackgroundIO
      def initialize(connection, queue)
        @connection, @queue = connection, queue
        @thread = nil
      end

      # Ensures that only one thread is in the block given to it at any given
      # time. If there is already a thread working on the block, it returns
      # without yielding. 
      #
      def one_thread
        yield
      end
      
      def try_send
        p [:try_send, @queue.size]
        return if @queue.empty?
        start_thread unless @thread

        one_thread do
          @connection.try_connect
          
          while @connection.established? && !queue.empty?
            msg = queue.shift
            @connection.write(
              serializer.en(msg))
          end
        end
      end
    private
      def start_thread
        @thread = Thread.start do
          while !@queue.empty?
            p :background_try_send
            try_send
            sleep 0.1
          end
          
          @thread = nil
        end
      end
    end
    
    def initialize(destination)
      @send_queue = Queue.new
      @connection = Connection.new(destination)
    end
    
    # A queue of objects that are waiting to be sent. 
    #
    attr_reader :send_queue

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
      # Here's the strategy for sending messages now and later: 
      #  * is there already a Bac
      #  * try to send messages right now. If they can be sent, stop. 
      #  * l
      send_queue << obj
      
      @background_io ||= BackgroundIO.new(@connection, send_queue)
      @background_io.try_send
    end
  end
end