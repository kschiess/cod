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
      directory.publish('other.topic', 'other_message')
      directory.publish('some.topic', 'message')
      topic.get.should == 'message'
    end 
  end
  
  describe 'when encountering stale subscriptions' do
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
end