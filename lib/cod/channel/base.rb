
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
    
    # Returns true if the current channel permits transmission of channel.
    # This gets called while serializing a channel as part of a message. If
    # the answer here is false, an error is raised. 
    #
    # Overwrite this method if you want to forbid some channels from being 
    # transmitted over the wire. 
    #
    def may_transmit?(channel)
      true
    end
    
    # Returns a channel that is to be put instead of identifier into the
    # message that is currently being deserialized. If this method returns
    # nil, the identifier is #resolve'd normally and the result returned. 
    #
    # Overwrite this method if you have special deserialization needs, like 
    # replacing the client end of a channel with the servers corresponding 
    # entity. 
    # 
    def replaces(identifier)
      nil
    end
        
    # Returns the Identifier class below the current channel class. This is 
    # a helper function that should only be used by subclasses. 
    #
    def identifier_class
      self.class.const_get(:Identifier)
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
      # Do we know which channel we're being serialized through? Ask for
      # permission. 
      if serializing_channel = tls_get(:cod_serializing_channel)
        unless serializing_channel.may_transmit?(self)
          communication_error "#{self} cannot be transmitted via this channel."
        end
      end
      
      identifier
    end
    
    # Using an object previously returned by #to_wire_data, reconstitute the
    # original channel or something that is alike it. What you send to this
    # second channel (#put) you should be able to #get from this copy returned
    # here. 
    #
    def self.from_wire_data(obj)
      if deserializing_channel=tls_get(:cod_deserializing_channel)
        channel=deserializing_channel.replaces(obj)
        return channel if channel
      end
      
      obj.resolve
    end
    
    # Replaces the value of Thread.current[name] for the duration of the block
    # with value. Makes sure that the old value gets written back. 
    #
    def with_tls(name, value)
      old_val = Thread.current[name]
      Thread.current[name] = value
      
      yield
    ensure
      Thread.current[name] = old_val
    end
    
    # Returns the value of Thread.current[name]
    #
    def tls_get(name)
      Thread.current[name]
    end
    def self.tls_get(name)
      Thread.current[name]
    end
    
    # ---------------------------------------------------------- serialization
    
    # Serialize the message into a string. Overwrite this message if you want
    # to control the message format. 
    #
    def serialize(message)
      with_tls(:cod_serializing_channel, self) do
        Marshal.dump(message)
      end
    end
    
    # Deserializes a message (in message format, string) into the object that
    # was transmitted. Overwrite this message if you want to control the 
    # message format. 
    #
    def deserialize(buffer)
      with_tls(:cod_deserializing_channel, self) do
        Marshal.load(buffer)
      end
    end
  
    # Turns the object into a buffer (simple transport layer that prefixes a
    # size)
    #
    def transport_pack(message)
      serialized = serialize(message)
      buffer = [serialized.size].pack('l') + serialized
    end
    
    # Slices one message from the front of buffer and returns it. This
    # reverses the simple transport layer added to the string sent out by
    # #transport_pack.
    #
    def transport_unpack(buffer)
      size = buffer.slice!(0...4).unpack('l').first
      serialized = buffer.slice!(0...size)
      deserialize(serialized)
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