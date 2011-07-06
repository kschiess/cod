require 'weakref'

module Cod
  # Context will allow to produce channels retaining some state. Until now, 
  # this hasn't been neccessary. 
  #
  class Context
    def pipe(name=nil)
      Cod::Channel::Pipe.new(name)
    end
    
    def beanstalk(url, name=nil)
      Cod::Channel::Beanstalk.new(
        Connection::Beanstalk.new(url), name)
    end
    
    def tcp(destination)
      Cod::Channel::TCPConnection.new(destination)
    end

    def tcpserver(bind_to)
      Cod::Channel::TCPServer.new(bind_to)
    end
  end
end