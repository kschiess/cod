
module Cod
  # A cod channel based on IO.pipe. 
  class Pipe
    # Actively splits this pipe into two ends, a read end and a write end. The
    # original pipe is closed, leaving only the two ends to work with. The 
    # read end can only be read from (#get) and the write end can only be 
    # written to (#put).
    #
    def split
      [self, self]# TODO
    end
    
    # Writes a message object to the pipe. You can specify a custom object
    # serializer (including a string passthrough if that is what you want)
    # when constructing the pipe. 
    #
    # Using #put on a pipe instance will close the other pipe end. Subsequent
    # #get will raise a Cod::InvalidOperation. 
    #
    # Example: 
    #   pipe.put [:a, :message]
    #
    def put(obj)
    end
    
    # Reads a message object from the pipe. 
    #
    # Using #get on a pipe instance will close the other pipe end. Subsequent
    # #put will receive a Cod::InvalidOperation.
    #
    # Allowed options: 
    #   :timeout :: time to wait for a message to arrive, raises Cod::Timeout
    #
    # Example: 
    #   pipe.get # => obj
    #
    def get(opts={})
      # TODO :timeout
    end
  end
end