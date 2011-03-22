require 'spec_helper'

describe Cod::Channel::Beanstalk do
  def clear_tube(name)
    conn = pipe.beanstalk
    loop do
      break unless conn.peek_ready
      job = conn.reserve
      job.delete
    end
  end
  
  def channel(name=nil)
    described_class.new('localhost:11300', name)
  end
  
  context "anonymous tubes" do
    let!(:pipe) { channel() }
    before(:each) { clear_tube(pipe.tube_name) }
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
  end
  context "named tubes" do
    let(:tube_name) { __FILE__ + ".named_tubes" }
    before(:each) { clear_tube(tube_name) }

    let!(:pipe) { channel(tube_name) }
    after(:each) { pipe.close }
    
    it "should allow for simple messaging" do
      pipe.put 'test'
      
      # Construct another tube independently, the only common thing being the
      # tube_name
      other_pipe = channel(tube_name)
      other_pipe.get.should == 'test'
    end 
  end
end