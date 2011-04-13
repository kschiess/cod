require 'spec_helper'

describe Cod::Topic do
  let(:directory) { flexmock(:directory) }
  let(:incoming)  { flexmock(:incoming) }
  slet(:topic) { Cod::Topic.new('topic_string', directory, incoming) }
  
  describe "#close" do
    it "should close both channels" do
      [directory, incoming].each { |chan| 
        chan.should_receive(:close).once }
        
      topic.close
    end 
  end
end