require 'socket'

module Cod       
  # A tcp server channel. Messages are read from any of the connected sockets
  # in a round robin fashion. 
  #
  # == Synopsis
  #   server = Cod.tcp_server('localhost:12345') 
  #   server.get  # 'a message'
  #   msg, chan = server.get_ext
  #
  # There is no implementation of #put that would broadcast back to all
  # connected sockets, this is up to you to implement. Instead, you can use
  # one of two ways to obtain a channel for talking back to a specific client:
  # 
  #   msg, chan = server.get_ext 
  # 
  # chan is a two way connected channel to the specific client that has opened 
  # its communication with msg. 
  #
  #   # on the client: 
  #   client.put [client, :msg]
  #   # on the server
  #   chan, msg = server.get
  #
  # This means that you can transmit the client channel through the connection 
  # as part of the message you send. 
  # 
  class TcpServer < SocketServer
    def initialize(bind_to, serializer)
      super(serializer, TCPServer.new(*bind_to.split(':')))
    end
    
    def deserialize_special(socket, obj)
      if obj.kind_of?(TcpClient::OtherEnd)
        return back_channel(socket)
      end
      return obj
    end
    
    def back_channel(socket)
      TcpClient.new(
        TcpClient::Connection.new(socket, self), 
        serializer)    
    end
    
    # --------------------------------------------------------- service/client
    
    def service
      Service.new(self)
    end
    
    # @note It is really more convenient to just construct a Cod.tcp_client 
    # and ask that for a client object. In the case of TCP, this is enough. 
    #
    def client(answers_to)
      Service::Client.new(answers_to, answers_to)
    end
  end
end