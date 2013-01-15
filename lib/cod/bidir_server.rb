module Cod
  class BidirServer < SocketServer
    include Callbacks
    
    attr_reader :path
    
    def initialize(path, serializer)
      super serializer || SimpleSerializer.new, 
        UNIXServer.new(path)

      @path = path
    end
    
    def deserialize_special(socket, obj)
      case obj
        when Bidir::OtherEnd
          if obj.path == self.path
            return back_channel(socket)
          end
          
          channel = Bidir.new(serializer, nil, nil, nil)
          register_callback { |conn| 
            channel.socket= conn.recv_io(UNIXSocket) }
          return channel
      end
      
      obj
    end
    
    def back_channel(socket)
      Bidir.new(serializer, nil, socket, nil)
    end
  end
end