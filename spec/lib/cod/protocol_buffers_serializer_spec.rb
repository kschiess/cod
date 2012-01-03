require 'spec_helper'

begin 
  require 'protocol_buffers'
  require 'cod/protocol_buffers_serializer'
  
  describe Cod::ProtocolBuffersSerializer do
    Varint = ProtocolBuffers::Varint

    let(:io) { StringIO.new }
    let(:serializer) { described_class.new }
    
    def varint(int)
      io = StringIO.new
      io.set_encoding 'ASCII-8BIT'
      Varint.encode(io, int)
      io.string
    end
    
    describe '#en(obj)' do
      it "encodes message length as varint on the wire" do
        string = "String"
        serializer.en(" "*100).should == 
          varint(string.size) + string + 
          varint(100) + " "*100
      end 
    end
    describe '#de(io)' do
      class PseudoMessage
        def to_s
          " "*100
        end
        def parse(io)
          str = io.read(100)
          fail "Not a pseudo message" unless str == " "*100
          self
        end
        def self.parse(io)
          new.parse(io)
        end
      end
      
      it "decodes an encoded object" do
        io.write(serializer.en(PseudoMessage.new))
        io.write('eof') # extra bytes
        
        io.pos = 0 
        serializer.de(io).should be_kind_of(PseudoMessage)
        io.read(3).should == 'eof'
        io.eof?.should == true
      end 
    end
  end
rescue LoadError
end
