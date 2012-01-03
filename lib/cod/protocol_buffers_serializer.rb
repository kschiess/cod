# Install the ruby-protocol-buffers gem for this to work. 
require 'protocol_buffers'

module Cod
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