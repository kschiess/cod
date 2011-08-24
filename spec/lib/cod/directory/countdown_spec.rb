require 'spec_helper'

describe Cod::Directory::Countdown do
  let(:start_time) { Time.now }
  slet(:countdown) { described_class.new(30*60, start_time) }
  
  def min(min)
    min * 60
  end
  
  context "when started at start_time" do
    before(:each) { countdown.start(start_time) }

    context "@start_time" do
      let(:now) { start_time }

      it { should_not be_elapsed(now) } 
    end
    context "@start_time + 31 minutes" do
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
  end
  
  it "initializes in stopped mode" do
    countdown.should_not be_running
  end    
  it "allows construction and other methods without time argument" do
    countdown = described_class.new(10)
    countdown.elapsed?
    countdown.stop
    countdown.start
  end 
  it "allows construction with a number of seconds to count down" do
    cd = described_class.new(15)
    cd.start
    cd.should be_elapsed(Time.now+16)
  end 
end
