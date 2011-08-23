require 'spec_helper'

describe Cod::Directory do
  context "mocked channel" do
    let(:directory_channel) { flexmock(:directory_channel) }
    slet(:directory) { described_class.new(directory_channel) }
    describe "#close" do
      it "should close all resources" do
        directory_channel.should_receive(:close).once

        directory.close
      end 
    end
  end
  
  context "real channel" do
    let(:directory_channel) { Cod.pipe }
    slet(:directory) { described_class.new(directory_channel) }

    describe 'ping handling' do
      let(:ping_subscription_klass) {
        Struct.new(:backchannel) do
          def ===(o); true end
          def put(msg)
            backchannel.put [:ping, identifier]
          end
          def identifier; 42 end
          def stale?; false end
        end
      }
      let(:subscription) { ping_subscription_klass.new(directory_channel.dup) }

      before(:each) { 
        directory.subscribe subscription
      }

      it "directs pings back to the subscription" do
        flexmock(subscription).should_receive(:ping).once

        directory.publish 'foo', 'bar'
      end 
    end
  end
end