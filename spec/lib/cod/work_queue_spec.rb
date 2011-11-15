require 'spec_helper'

require 'timeout'
require 'cod/work_queue'

describe Cod::WorkQueue do
  let(:queue) { described_class.new }
  
  def try_for_a_while
    timeout(0.1) do
      yield
    end
  rescue Timeout::Error
  end
  
  describe 'background thread' do
    before(:each) { queue.predicate { true } }
    it "also works on work items" do
      ran = false
      queue.schedule { ran = true }
      try_for_a_while {
        Thread.pass until ran
      }
      ran.should == true
    end 
  end
  describe '#predicate' do
    # Start out with a predicate that blocks all work
    before(:each) {   
      @running = false
      queue.predicate { running? }
    }
    def running?
      @running
    end
    
    it "should not do work" do
      queue.schedule { fail }
      queue.try_work
    end 
    context "when the predicate evaluates to true" do
      it "should do work" do
        n = 0
        queue.schedule { n += 1 }
        @running = true
        queue.try_work
        n.should == 1
      end 
    end
  end
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