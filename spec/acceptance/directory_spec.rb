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
end