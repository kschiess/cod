module Cod
  class Service
    # Waits until a request arrives on the service channel. Then reads that
    # request and hands it to the block given. The block return value
    # will be returned to the service client. 
    #
    # Use Cod::Client to perform the service call. This will keep track of 
    # messages sent and answers received and a couple of other things. 
    # 
    #
    def one
      
    end

    # A service client. 
    #
    class Client
      
    end
  end
  
end