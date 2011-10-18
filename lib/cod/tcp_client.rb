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
    
    class IOThread
      def initialize(connection, send_queue)
        @connection = connection
        @send_queue = send_queue

        @m_running = Mutex.new
        @running = false
      end
      
      attr_reader :connection
      
      def running?
        @running
      end
      
      def start
        # TODO worry about reconnects. Should we loose objects in certain
        # cases?
        
        @m_running.synchronize { @running = true }
        # Thread.start do
          connection.try_connect
          
          while connection.established? && !send_queue.empty?
            obj = send_queue.shift
            
            p [:sending, obj]
            connection.write(serializer.en(obj))
          end
          
          @m_running.synchronize { @running = false }
        # end
      end
    end
    
    def initialize(destination)
      @send_queue = Queue.new
      @connection = Connection.new(destination)
      @io_thread = IOThread.new(@connection, @send_queue)
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
      send_enqueue obj
      Thread.pass
    end
    
  private
    def send_enqueue(obj)
      send_queue << obj
      
      unless @io_thread.running?
        @io_thread.start
      end
    end
  end
end