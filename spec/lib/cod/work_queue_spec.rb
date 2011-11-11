require 'spec_helper'

require 'cod/work_queue'

describe Cod::WorkQueue do
  let(:queue) { described_class.new }
  
  describe '#schedule' do
    # Setting the predicate to false should disable all work
    before(:each) { queue.predicate { false } }
    
    it "adds a work item to the queue" do
      expect {
        queue.schedule { work }
      }.to change { queue.size }.by(1)
    end 
  end
  describe '#shutdown' do
    it "shuts down the background thread" do
      queue.schedule { work }
      expect {
        queue.shutdown
      }.to change { Thread.list.size }.by(-1)
    end 
  end
end