require 'spec_helper'

describe Cod::Channel::Beanstalk do
  let!(:pipe) { described_class.new('localhost:11300') }
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
end