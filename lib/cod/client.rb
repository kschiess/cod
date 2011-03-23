
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
      @incoming = answers
      @outgoing = requests
    end

    # Calls the service in a synchronous fashion. Returns the message the
    # server sends back. 
    #
    def call(message)
    end
    
    # Closes all resources that are held in the client. 
    #
    def close
      incoming.close
      outgoing.close
    end
  end
end