module Cod
  # Cod::Service abstracts the pattern where you send a request to a central
  # location (with possibly multiple workers handling requests) and receive an
  # answer. It solves problems related to timeouts, getting _your_ answer and
  # not any kind of answer, etc... 
  # 
  # Synopsis: 
  #   # On the server end: 
  #   service = Cod.service(central_location)
  #   service.one { |request| :answer }
  #
  #   # On the client end: 
  #   service = Cod.client(central_location, answer_here)
  #
  #   # asynchronous, no answer
  #   service.notify [:a, :request]   # => nil
  #   # has an answer: 
  #   service.call [:a, :request]   # => :answer
  #
  # Depending on the setup of the channels, this class can be used to
  # implement intra- and interprocess communication, very close to RPC. There
  # are two ways to build on this: 
  #
  # * Using method_missing, implement real RPC on top. This is usually rather
  #   simple (since Cod does a lot of work), see github.com/kschiess/zack for
  #   an example of this.
  # 
  # * Using the 'case' gem, implement servers in an (erlang) actor like
  #   fashion. 
  #
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