
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
    
    def _dump(depth)
      # TODO should be: Marshal.dump(to_wire_data)
      
      # Do we know which channel we're being serialized through? Ask for
      # permission. 
      if serializing_channel = tls_get(:cod_serializing_channel)
        unless serializing_channel.may_transmit?(self)
          communication_error "#{self} cannot be transmitted via this channel."
        end
      end
      
      Marshal.dump(identifier)
    end
        
    def self._load(string)
      # TODO should be: from_wire_data(Marshal.load(string))
      
      identifier = Marshal.load(string)
      
      if deserializing_channel=tls_get(:cod_deserializing_channel)
        channel=deserializing_channel.replaces(identifier)
        return channel if channel
      end
      
      identifier.resolve
    end
    
  private
    
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
  
    def serialize(message)
      with_tls(:cod_serializing_channel, self) do
        Marshal.dump(message)
      end
    end
    
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