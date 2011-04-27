require 'spec_helper'

describe Cod::Channel::Base do
  let(:base) { described_class.new }
  
  describe "#marshal_dump" do
    after(:each) { Thread.current[:cod_serializing_channel] = nil }
    
    it "should ask the serializer for permission when serializing channels" do
      serializer = Thread.current[:cod_serializing_channel] = 
        flexmock(:serializer)

      serializer.
        should_receive(:may_transmit?).with(base).and_return(false)
        
      expect {
        base.marshal_dump
      }.to raise_error(Cod::Channel::CommunicationError)
    end 
  end
end