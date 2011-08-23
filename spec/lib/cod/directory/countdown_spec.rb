require 'spec_helper'

describe Cod::Directory::Countdown do
  let(:start_time) { Time.now }
  slet(:countdown) { described_class.new(start_time) }
  
  def min(min)
    min * 60
  end
  
  context "at start_time" do
    let(:now) { start_time }
    
    it { should_not be_elapsed(now) } 
  end
  context "at start_time + 31 minutes" do
    let(:now) { start_time + min(31) }
    
    it { should be_elapsed(now) } 

    context "when stopped in time" do
      before(:each) { countdown.stop(start_time + min(10)) }
      
      it { should_not be_running }
      it { should_not be_elapsed(now) } 
    end
    context "when stopped/restarted" do
      before(:each) { countdown.stop(start_time + min(10)) }
      before(:each) { countdown.start(start_time + min(15)) }

      it { should be_running }
      it { should_not be_elapsed(now) } 
      it { should be_elapsed(now+min(15)) } 
    end
  end
  
      
  it "allows construction and other methods without time argument" do
    countdown = described_class.new
    countdown.elapsed?
    countdown.stop
    countdown.start
  end 
end