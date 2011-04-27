
module Cod
  # A client that consumes a service (Cod::Service).
  #
  class Client
    attr_reader :incoming
    attr_reader :outgoing
    
    # Create a new client and tie it to an answer channel. The answer channel
    # will often be anonymous - no one except the service needs to write
    # there. 
    #
    def initialize(requests, answers)
      @timeout = 1
      @incoming = answers
      @outgoing = requests
    end

    # Calls the service in a synchronous fashion. Returns the message the
    # server sends back. 
    #
    def call(message=nil)
      outgoing.put [message, incoming, true]
      incoming.get(:timeout => @timeout)
    end
    
    # This sends the server a message without waiting for an answer. The
    # server will throw away the answer produced. 
    #
    def notify(message)
      outgoing.put [message, incoming, false]
      nil
    end
    
    # Closes all resources that are held in the client. 
    #
    def close
      incoming.close
      outgoing.close
    end
  end
end