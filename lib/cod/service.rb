
module Cod
  # A service that receives requests and answers. 
  #
  class Service
    # Incoming channel for requests.
    attr_reader :incoming
    
    def initialize(channel)
      @incoming = channel
    end
    
    # Calls the given block with the next request and returns the block answer
    # to the service client. 
    #
    def one
      call = incoming.get
      
      answer = yield(call.message)
      
      call.channel.put call.response(answer)
    end
    
    # Loops forever, yielding requests to the block given and returning the 
    # answers to the client.
    #
    def each
    end
    
    # Releases all resources held by the service. 
    #
    def close
      incoming.close
    end
  end
end