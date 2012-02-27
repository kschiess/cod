module Cod
  # The simplest of all serializers, one that uses Marshal.dump and
  # Marshal.load as a message format. Use this as a template for your own wire
  # format serializers.
  #
  class SimpleSerializer
    # Serializes obj into a format that can be transmitted via the wire. In
    # this implementation, it will use Marshal.dump to turn the obj into a 
    # string. 
    #
    # @param obj [Object] to dump
    # @return [String] transmitted over the wire
    # 
    def en(obj)
      Marshal.dump(obj)
    end
    
    # Reads as many bytes as needed from io to reconstruct one message. Turns
    # the message back into a Ruby object according to the rules of the serializer. 
    # In this implementation, it will use Marshal.load to turn the object 
    # from a String to a Ruby Object.
    #
    # @param io [IO] to read one message from
    # @return [Object] that has been deserialized
    #
    def de(io)
      if block_given?
        Marshal.load(io, Proc.new)
      else
        Marshal.load(io)
      end
    end
  end
end