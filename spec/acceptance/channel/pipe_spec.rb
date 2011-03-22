require 'spec_helper'

describe Cod::Channel::Pipe do
  context "anonymous pipe" do
    let!(:pipe) { described_class.new }
    after(:each) { pipe.close }
    
    it "should have simple message semantics" do
      # Split the channel into a write end and a read end. Otherwise
      # reading / writing from the channel will close the other end, 
      # leaving us unable to perform all operations.
      read = pipe
      write = pipe.dup
      
      write.put 'message1'
      write.put 'message2'

      read.should be_waiting
      read.get.should == 'message1'
      read.should be_waiting
      read.get.should == 'message2'
      
      read.should_not be_waiting
    end 
    it "should not allow writing after a read" do
      # Put to a duplicate, so that the test does what it says.
      pipe.dup.put 'foo'
      
      pipe.get
      
      lambda {
        pipe.put 'test'
      }.should raise_error(Cod::Channel::DirectionError)
    end
    it "should not allow reading after a write" do
      
      lambda {
        pipe.put 'test'
        pipe.get
      }.should raise_error(Cod::Channel::DirectionError)
    end  
    it "should work after a fork" do
      child_pid = fork do
        pipe.put 'test'
        pipe.put Process.pid
      end
      
      begin
        pipe.get.should == 'test'
        pipe.get.should == child_pid
      ensure
        Process.wait(child_pid)
      end
    end 
    it "should also transfer objects" do
      read, write = pipe, pipe.dup
      
      write.put 1
      write.put true
      write.put :symbol
      
      read.get.should == 1
      read.get.should == true
      read.get.should == :symbol
    end 
  end
end