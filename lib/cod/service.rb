
module Cod
  # A service that receives requests and answers. A service has always at
  # least one provider that creates an instance of this class and waits in
  # #one or #each. Clients then instantiate Cod::Client and #call the service.
  #
  # Example: 
  #   # service side
  #   service = Cod::Service.new(incoming_channel)
  #   service.one { |msg| 'answer' }
  # 
  #   # client side
  #   client = Cod::Client.new(incoming_channel, service_channel)
  #   client.call('call message') # => 'answer'
  #
  # == Topology
  # 
  # A service always has (potentially) multiple clients and depending on the
  # transport layer used, one or more workers handling the clients request.
  # They will always receive the messages in a round robin fashion; the
  # service corresponds in this case to the channel address; clients need not
  # know the workers involved. 
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
      message, answer_channel, needs_answer = incoming.get      
      
      answer = yield(message)
      
      if needs_answer
        answer_channel.put answer
      end
    end
    
    # Loops forever, yielding requests to the block given and returning the 
    # answers to the client.
    #
    def each(&block)
      loop do
        one(&block)
      end
    end
    
    # Releases all resources held by the service. 
    #
    def close
      incoming.close
    end
  end
end