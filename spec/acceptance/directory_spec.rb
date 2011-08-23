require 'spec_helper'

describe "Directory & Topics" do
  let!(:directory_channel) { Cod.pipe }
  let(:directory) { Cod::Directory.new(directory_channel) }
  
  after(:each) { directory.close }
  
  context "subscribing to 'some.topic'" do
    let(:channel) { Cod.pipe }
    let!(:topic)   { Cod::Topic.new('some.topic', directory_channel.dup, channel) }
    after(:each)  { topic.close }

    specify "basic semantics" do
      directory.publish('other.topic', 'other_message').should == 0
      directory.publish('some.topic', 'message').should == 1
      topic.get(timeout: 1).should == 'message'
    end 
  end
  describe 'subscription management:' do
    describe 'stale subscriptions' do
      let(:channel) { Cod.pipe }
      let!(:topic)   { Cod::Topic.new('', directory_channel.dup, channel) }

      it "should never subscribe when a channel cannot be extracted" do
        # No exception raised when rehydrating pipes
        # serialized over pipes when the original pipes are closed already 
        topic.close
        directory.publish('', 'test')

        directory.subscriptions.size.should == 0
      end 
      it "should unsubscribe channels that fail" do
        directory.publish('', 'test')
        directory.subscriptions.size.should == 1

        topic.close
        directory.publish('', 'test')
        directory.subscriptions.size.should == 0
      end
    end
    describe 'ping handling' do
      let(:ping_subscription_klass) {
        Struct.new(:backchannel) do
          def ===(o); true end
          def put(msg)
            backchannel.put [:ping, identifier]
          end
          def identifier; 42 end
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