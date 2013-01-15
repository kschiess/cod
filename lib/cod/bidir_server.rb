module Cod
  class BidirServer < SocketServer
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
          fail
      end
      
      obj
    end
    
    def back_channel(socket)
      Bidir.new(serializer, nil, socket, nil)
    end
  end
end