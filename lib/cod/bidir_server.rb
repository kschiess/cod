module Cod
  class BidirServer < SocketServer
    attr_reader :serializer
    
    def initialize(name, serializer)
      super serializer, UNIXServer.new(name)
    end
  end
end