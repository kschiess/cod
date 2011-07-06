require 'spec_helper'

describe Cod::ObjectIO::Writer do
  let(:connection_factory) { flexmock(:connection_factory) }
  let(:serializer) { flexmock(:serializer, :serialize => '.') }

  before(:each) { connection_factory.should_receive(:do).by_default }
  
  let(:writer) { described_class.new(serializer) { connection_factory.do } }
  
  context "if a connection can't be made" do
    it "looses the message" do
      writer.put 'message'
    end
    it "attempts reconnect before every send" do
      io = flexmock(:io)

      connection_factory.should_receive(:do => io).once
      io.should_receive(:write).with('.').once

      writer.put 'message'
    end
  end
end