require 'spec_helper'

describe Cod::Channel::Base do
  let(:base) { described_class.new }
  
  describe "#_dump" do
    after(:each) { Thread.current[:cod_serializing_channel] = nil }
    
    it "should ask the serializer for permission when serializing channels" do
      serializer = Thread.current[:cod_serializing_channel] = 
        flexmock(:serializer)

      serializer.
        should_receive(:may_transmit?).with(base).and_return(false)
        
      expect {
        base._dump(-1)
      }.to raise_error(Cod::Channel::CommunicationError)
    end 
  end
  describe "._load(str)" do
    after(:each) { Thread.current[:cod_deserializing_channel] = nil }
    
    it "should permit the deserializer to transform channels in the message" do
      deserializer = Thread.current[:cod_deserializing_channel] = 
        flexmock(:deserializer)
        
      deserializer.
        should_receive(:replaces).with(:wire_str).and_return(:replaced_channel)
      
      described_class._load(Marshal.dump(:wire_str))
    end 
  end
end