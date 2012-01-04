# Install the ruby-protocol-buffers gem for this to work. 
require 'protocol_buffers'

module Cod
  # Serializes a protocol buffer (googles protobufs) message to the wire and
  # reads it back. Protobufs are not self-delimited, this is why we store the
  # messages in the following on-wire format: 
  #
  #   LEN(class) BYTES(class) LEN(message) BYTES(message)
  #
  # where LEN is a varint representation of the length of the contained item
  # and BYTES are the binary bytes of said item. 
  #
  # This is not the most space efficient manner of representing things on the
  # wire. It also assumes that you have defined the message classes on both
  # sides (client and server). 
  #
  # For applications where this is a problem, you can always use this
  # implementation as a guide for your own implementation. For example,
  # message polymorphism could be coded as a single byte on the wire, allowing
  # for one of 255 messages to be sent each time. For really efficient
  # transfers, you could even send a fixed amount of bytes and one message,
  # getting the most out of protobufs. 
  #
  # Please see examples/protocol-buffers/master_child.rb for information
  # on how to use this. 
  #
  class ProtocolBuffersSerializer
    Varint = ProtocolBuffers::Varint
    
    def en(obj)
      sio = ProtocolBuffers.bin_sio
      
      # Assuming that obj is a protocol buffers message object, this should 
      # work: 
      klass_name = obj.class.name
      buffer = obj.to_s

      Varint.encode(sio, klass_name.size)
      sio.write(klass_name)
      
      Varint.encode(sio, buffer.size)
      sio.write(buffer)
      
      sio.string
    end
    
    def de(io)
      klass_size = Varint.decode(io)
      klass_name = io.read(klass_size)
      
      klass = self.class.const_get(klass_name)
      
      msg_size = Varint.decode(io)
      limited_io = LimitedIO.new(io, msg_size)
      klass.parse(limited_io)
    end
  end
end