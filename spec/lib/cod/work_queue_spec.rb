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
    describe '#clear_thread_semaphore and #thread_semaphore_set?' do
      it "is false after #clear_thread_semaphore" do
        queue.thread.kill
        queue.clear_thread_semaphore
        queue.thread_semaphore_set?.assert == false
      end 
      it "becomes true again after a while" do
        queue.clear_thread_semaphore
        try_for_a_while {
          Thread.pass until queue.thread_semaphore_set?
        }
        queue.thread_semaphore_set?.assert == true
      end
    end
    
    it "also works on work items" do
      ran = false
      queue.schedule { ran = true }
      
      queue.predicate { true }
      try_for_a_while {
        Thread.pass until ran
      }
      ran.assert == true
    end 
    it "should not reenter the try_work" do
      executed_in_thread = false
      main_thread = Thread.current
      
      10.times do 
        queue.schedule { 
          if Thread.current == main_thread
            Thread.pass until queue.thread_semaphore_set?
          else
            # We don't want to come in here, ever.
            executed_in_thread = true
          end }
      end

      queue.predicate { true }
      
      queue.clear_thread_semaphore
      queue.try_work
    
      executed_in_thread.assert == false
    end 
  end
  describe '#predicate' do
    # shuts down the thread, so the sole interaction is through try_work
    before(:each) { queue.shutdown }
    
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
        n.assert == 1
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
  describe '#exclusive' do
    it "isn't interrupted by work in the thread" do
      n = 0
      100.times { queue.schedule { n += 1} }
      queue.exclusive {
        queue.predicate { true }
        sleep 0.1
        n.assert == 0
      }
    end 
  end
  describe 'after #shutdown' do
    before(:each) { queue.shutdown }
    
    it "still works" do
      queue.predicate { true }

      answer = :no
      queue.schedule { answer = :yes }
      
      queue.try_work
      answer.assert == :yes
    end
    it "ignores further shutdowns" do
      queue.shutdown
    end  
  end

  describe 'when work is scheduled' do
    before(:each) { queue.schedule { } }

    it "should evaluate #predicate in one thread only" do
      evaluating_threads = {}
      queue.predicate { 
        sleep 0.01
        evaluating_threads[Thread.current] = true
        false }
      
      queue.try_work

      evaluating_threads.size.assert == 1
    end 
  end
end