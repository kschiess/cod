require 'spec_helper'

describe "Directory & Topics" do
  context "subscribing to 'some.topic'" do
    let!(:directory_channel) { Cod.pipe }
    let(:directory) { Cod::Directory.new(directory_channel) }
    after(:each) { directory.close }
    
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
    describe 'stale subscriptions (exceptions)' do
      let!(:directory_channel) { Cod.pipe }
      let(:directory) { Cod::Directory.new(directory_channel) }
      after(:each) { directory.close }
      
      let(:channel) { Cod.pipe }
      let!(:topic)   { Cod::Topic.new('', directory_channel.dup, channel) }
      after(:each) { topic.close }

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
    describe 'stale subscriptions (topic not answering)' do
      let(:directory_channel) { Cod.beanstalk('localhost:11300', 'dspec1') }
      let(:topic_channel) { Cod.beanstalk('localhost:11300', 'dspec2') }
      
      let!(:directory) { Cod::Directory.new(directory_channel.dup) }
      let!(:topic) { Cod::Topic.new('', directory_channel, topic_channel) }
      
      after(:each) { directory.close; topic.close }
      
      it "should be created with the timer stopped" do
        directory.process_control_messages
        
        directory.should have(1).subscriptions
        directory.subscriptions.each do |subscription|
          subscription.countdown.should_not be_running
        end
      end
      it "start counting on every message sent" do
        directory.publish '', :test
        
        directory.should have(1).subscriptions
        directory.subscriptions.each do |subscription|
          subscription.countdown.should be_running
        end
      end
      it "unsubscribe stale subscriptions after 30 minutes" do
        topic.close
        directory.publish '', :holler
        
        t = Time.now + 31*60
        
        # If we look at time t, the only subscription should be stale: 
        subscription = directory.subscriptions.first
        subscription.should be_stale(t)
        
        directory.process_control_messages(t)
        directory.subscriptions.should have(0).elements
      end 
    end
    describe 'renewing subscriptions' do
      let(:directory_channel) { Cod.pipe }
      let(:topic_channel) { Cod.pipe }
      
      let!(:directory) { Cod::Directory.new(directory_channel.dup) }
      let!(:topic) { Cod::Topic.new('', directory_channel, topic_channel) }
      
      after(:each) { directory.close; topic.close }

      it "dedupes subscriptions based on id" do
        topic.renew_subscription
        directory.process_control_messages
        
        directory.should have(1).subscriptions
      end
      it "raises Exception if the same identifier subscribes twice" do
        topic.subscribe
        
        expect {
          directory.process_control_messages
        }.to raise_error
        directory.should have(1).subscriptions
      end 
    end
  end
end