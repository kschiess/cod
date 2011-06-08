
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
    
    # Returns the Identifier class below the current channel class. This is 
    # a helper function that should only be used by subclasses. 
    #
    def identifier_class
      self.class.const_get(:Identifier)
    end

    # Something to put into the data stream that is transmitted through a 
    # channel that allows reconstitution of the channel at the other end. 
    # The invariant is this: 
    #
    #   # channel1 and channel2 are abstract channels that illustrate my 
    #   # meaning
    #   channel1.put channel2
    #   channel2a = channel1.get
    #   channel2a.put 'foo'
    #   channel2.get # => 'foo'
    #   
    # Note that this should also work if channel1 and channel2 are the same. 
    #
    def identifier
      identifier_class.new(self)
    end
    
    # ------------------------------------------------------------ marshalling

    # Makes sure that we don't marshal this object, but the memento object
    # returned by identifier. 
    #
    def _dump(d)
      wire_data = to_wire_data
      Marshal.dump(wire_data)
    end
     
    # Loads the object from string. This doesn't always return the same kind
    # of object that was serialized. 
    #
    def self._load(string)
      wire_data = Marshal.load(string)
      from_wire_data(wire_data)
    end
    
  private
  
    # Returns the objects that need to be transmitted in order to reconstruct
    # this object after transmission through the wire. 
    #
    # If you're using a serialisation method other than the Ruby built in 
    # one, use this to obtain something in lieu of a channel that can be sent
    # through the wire and reinterpreted at the other end. 
    #
    # Example: 
    #
    #   # this should work: 
    #   obj = channel.to_wire_data
    #   channel_equiv = Cod::Channel::Base.from_wire_data(obj)
    #
    def to_wire_data
      identifier
    end
    
    # Using an object previously returned by #to_wire_data, reconstitute the
    # original channel or something that is alike it. What you send to this
    # second channel (#put) you should be able to #get from this copy returned
    # here. 
    #
    def self.from_wire_data(obj)
      obj.resolve
    end
    
    # ---------------------------------------------------------- error raising
   
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