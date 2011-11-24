module Cod
  class Service
    def initialize(channel)
      @channel = channel
    end
    
    # Waits until a request arrives on the service channel. Then reads that
    # request and hands it to the block given. The block return value
    # will be returned to the service client. 
    #
    # Use Cod::Client to perform the service call. This will keep track of 
    # messages sent and answers received and a couple of other things. 
    # 
    #
    def one
      rq, answer_chan = @channel.get
      res = yield(rq)
      answer_chan.put res if answer_chan
    end

    # A service client. 
    #
    class Client
      def initialize(server_chan, answer_chan=nil)
        @server_chan, @answer_chan = server_chan, answer_chan || server_chan
      end
      
      def call(rq)
        @server_chan.put [rq, @answer_chan]
        @answer_chan.get
      end
      
      def notify(rq)
        @server_chan.put [rq, nil]
      end
      
      def close
        @server_chan.close
        @answer_chan.close
      end
    end
  end
  
end