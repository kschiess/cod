
module Cod
  # A service that receives requests and answers. 
  #
  class Service
    def initialize(channel)
    end
    
    # Reads the next message from the service. This returns a <message,
    # channel> tuple. You should answer by writing to the channel; clients may
    # be waiting for the answer. 
    #
    def read
    end
    
    # Calls the given block with the next request and returns the block answer
    # to the service client. 
    #
    def one
    end
    
    # Loops forever, yielding requests to the block given and returning the 
    # answers to the client.
    #
    def each
    end
  end
end