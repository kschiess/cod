require 'thread'

module Cod
  # Acts as a channel that connects to a tcp listening socket on the other
  # end. 
  #
  class TcpClient
    # A connection that can be down. This allows elegant handling of
    # reconnecting and delaying connections. 
    #
    # Synopsis: 
    #   connection = Connection.new('foo:123')
    #   connection.try_connect
    #   connection.write('buffer')
    #   connection.established? # => false
    #   connection.close
    #
    class Connection # :nodoc: 
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

      # Closes the connection and stops reconnection. 
      #
      def close
        @socket.close if @socket
        @socket = nil
      end
    end
    
    # A background thread that sends messages from the queue to the connection
    # as fast as it can. Once the queue is exhausted, the background thread
    # waits until the queue again populates (#try_send).
    #
    class BackgroundIO
      def initialize(connection, queue)
        @connection, @queue = connection, queue
        @serializer = SimpleSerializer.new
        @thread = nil
        
        @queue_full_cv = ConditionVariable.new
        @queue_full_m  = Mutex.new
        
        start_thread
      end

      # Tries to send all messages from @queue to @connection. If there is 
      # a reason this cannot happen (broken connection, etc.), run a background
      # thread that will retry. 
      #
      def try_send
        return if @queue.empty?

        signal_full_queue
      end

      # Shuts down the thread that is running in the background. 
      #
      def shutdown
        return unless @thread
        
        # Signal that we would like to shut down
        @shutdown_requested = true
        # Wake up the thread that is probably waiting for the queue
        signal_full_queue
        # Join the thread
        @thread.join
        
        @thread = nil
      end
    private
      def signal_full_queue
        @queue_full_m.synchronize {
          @queue_full_cv.signal
        }
      end
      def wait_until_queue_fills
        @queue_full_m.synchronize { @queue_full_cv.wait(@queue_full_m) }
      end

      def start_thread
        @thread = Thread.start do
          Thread.current.abort_on_exception= true
          
          run
        end
      end
      
      def run
        loop do
          # We first try to send whatever is there, because we might be 
          # in a start-up race condition where the CV is signaled before
          # we wait on it. Try to send anyway, and then wait.
          while !@queue.empty? && !@shutdown_requested
            # Busy loop until we can send the data. Maybe this is too 
            # time consuming; introduce a backoff algo later on?
            do_send
            Thread.pass
          end

          # Wait until someone thinks that there is work to do.
          break if @shutdown_requested 

          wait_until_queue_fills
        end
      end
      
      def do_send
        @connection.try_connect
        
        while @connection.established? && !@queue.empty?
          # TODO maybe we should abort when the socket is not ready?
          return if @shutdown_requested
          msg = @queue.shift

          @connection.write(
            @serializer.en(msg))
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

    # Closes all underlying connections. You should only call this if you 
    # don't want to use the channel again, since it will also stop reconnection
    # attempts. 
    #
    def close
      @connection.close
      @background_io.shutdown if @background_io
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
      send_queue << obj

      # Make sure that we have a background io thread
      @background_io ||= BackgroundIO.new(@connection, send_queue)
      
      # Try sending the messages right now. This only does work if the
      # thread is not already doing it. 
      @background_io.try_send
    end
  end
end