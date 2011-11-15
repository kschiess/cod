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

      # Reads from the connection in a nonblocking manner.
      #
      def read_nonblock(bytes)
        if @socket
          return @socket.read_nonblock(bytes)
        end
        
        raise Errno::EAGAIN
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
      def try_connect
      end
      def established?
        true
      end
      def write(buffer)
        @socket.write(buffer)
      end
    end
    
    def initialize(destination, serializer)
      @recv_queue = Array.new
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
    
    # A queue of objects that have already been received.
    #
    attr_reader :recv_queue

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
    #   serializer :: Context given to the serializer. This allows passing 
    #                 in a context object to enrich deserialisation.
    #
    def get(opts={})
      loop do
        return recv_queue.shift if queued?
        
        process_incoming(opts)
      end
    end
  private
    def send(msg)
      @connection.write(
        @serializer.en(msg))
    end
  
    def process_incoming(opts)
      # TODO figure out how to deal with chunks
      context = opts[:serializer]
      
      # Read a large bit from the buffer. We currently don't deal with large
      # transmissions well at all. 
      buffer = @connection.read_nonblock(1024*1024)
      
      marked_buffer = StringIO.new(buffer)
      while !marked_buffer.eof?
        recv_queue << @serializer.de(marked_buffer, context)
      end
    rescue Errno::EAGAIN
      # Nothing to read, no problem
    end
    def queued?
      !recv_queue.empty?
    end
  end
end