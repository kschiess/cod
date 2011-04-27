
module Cod
  # TODO document write/read semantics
  # TODO document dup behaviour
  # TODO document object serialisation
  class Channel::Base
    # Writes a Ruby object (the 'message') to the channel. This object will 
    # be queued in the channel and become available for #get in a FIFO manner.
    #
    # Issuing a #put also closes the channel instance for subsequent #get's. 
    #
    # Example: 
    #   chan.put 'test'
    #   chan.put true
    #   chan.put :symbol
    #
    def put(message)
      not_implemented
    end
    
    # Reads a Ruby object (a message) from the channel. Some channels may not
    # allow reading after you've written to it once. Options that work: 
    #
    #   :timeout :: Time to wait before throwing a Cod::Channel::TimeoutError.
    #
    def get(opts={})
      not_implemented
    end
    
    # Returns true if there are messages waiting in the channel. 
    #
    def waiting?
      not_implemented
    end
    
    def close
      not_implemented
    end
    
    def identifier
      not_implemented
    end
    
    # Returns the Identifier class below the current channel class. This is 
    # a helper function that should only be used by subclasses. 
    #
    def identifier_class
      self.class.const_get(:Identifier)
    end
    
    def marshal_dump
      identifier
    end
    
    def marshal_load(identifier)
      temp = identifier.resolve
      initialize_copy(temp)
    end
    
  private
    def serialize(message)
      Marshal.dump(message)
    end
    
    def deserialize(buffer)
      Marshal.load(buffer)
    end
  
    # Turns the object into a buffer (simple transport layer that prefixes a
    # size)
    #
    def transport_pack(message)
      serialized = serialize(message)
      buffer = [serialized.size].pack('l') + serialized
    end
    
    # Slices one message from the front of buffer
    #
    def transport_unpack(buffer)
      size = buffer.slice!(0...4).unpack('l').first
      serialized = buffer.slice!(0...size)
      deserialize(serialized)
    end
   
    def direction_error(msg)
      raise Cod::Channel::DirectionError, msg
    end

    def communication_error(msg)
      raise Cod::Channel::CommunicationError, msg
    end
    
    def not_implemented
      raise NotImplementedError, 
        "You called a method in Cod::Channel::Base. Missing implementation in "+
        "the subclass!"
    end
  end
end