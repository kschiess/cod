
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
    def initialize(requests, answers, timeout=1)
      @timeout = timeout
      @incoming = answers
      @outgoing = requests
      @request_id = 0
    end

    # Calls the service in a synchronous fashion. Returns the message the
    # server sends back. 
    #
    def call(message=nil)
      expected_id = next_request_id
      outgoing.put envelope(expected_id, message, incoming, true)
      
      start_time = Time.now
      loop do
        received_id, answer = incoming.get(:timeout => @timeout)
        return answer if received_id == expected_id
        
        # We're receiving answers with request_ids that are outside the 
        # window that we would expect. Something is seriously amiss. 
        raise Cod::Channel::CommunicationError, 
          "Missed request." unless earlier?(expected_id, received_id)
          
        # We've been waiting (and consuming answers) for too long - overall
        # timeout has elapsed. 
        raise Cod::Channel::TimeoutError, 
          "Timed out while waiting for service request answer." \
            if (Time.now-start_time) > @timeout
      end
    end
    
    # This sends the server a message without waiting for an answer. The
    # server will throw away the answer produced. 
    #
    def notify(message=nil)
      outgoing.put envelope(next_request_id, message, incoming, false)
      nil
    end
    
    # Closes all resources that are held in the client. 
    #
    def close
      incoming.close
      outgoing.close
    end
    
  private
  
    # Creates a message to send to the service. 
    #
    def envelope(id, message, incoming_channel, needs_answer)
      [id, message, incoming_channel, needs_answer]
    end
  
    # Returns a sequence of request ids.
    #
    def next_request_id
      @request_id += 1
    end
    
    # True if the received request id answers a request that has been 
    # earlier than the expected request id.
    #
    def earlier?(expected, received)
      expected > received
    end
  end
end