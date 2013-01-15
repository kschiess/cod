module Cod
  class BidirServer < SocketServer
    attr_reader :serializer
    
    def initialize(name, serializer)
      super serializer || SimpleSerializer.new, 
        UNIXServer.new(name)
    end
    
    def deserialize_special(socket, obj)
      case obj
        when Bidir::OtherEnd
          return Bidir.new(serializer, socket, nil)
      end
      
      obj
    end
  end
end