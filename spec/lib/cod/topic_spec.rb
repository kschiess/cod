require 'spec_helper'

describe Cod::Topic do
  include FlexMock::ArgumentTypes
  
  def cmd(cmd)
    on { |e| e.first == cmd }
  end
  
  let(:directory) { flexmock(:directory) }
  let(:incoming)  { flexmock(:incoming) }
  slet(:topic) { described_class.new('topic_string', directory, incoming) }
  
  # Defaults for directory and incoming mock.
  before(:each) { 
    directory.
      should_receive(:put).by_default
    incoming.
      should_receive(:get).by_default
  }
  
  describe "#close" do
    it "should close both channels" do
      [directory, incoming].each { |chan| 
        chan.should_receive(:close).once }
        
      directory.should_receive(:put)
        
      topic.close
    end 
  end
  describe '#get' do
    it "sends back a ping" do
      directory.
        should_receive(:put).with(cmd(:subscribe)).
        should_receive(:put).with(cmd(:ping)).once
      
      topic.get
      
      
    end 
  end
end