require 'spec_helper'

describe Cod::Channel::Beanstalk do
  # Removes all jobs from a beanstalk tube by name
  def clear_tube(name)
    conn = channel.beanstalk
    loop do
      break unless conn.peek_ready
      job = conn.reserve
      job.delete
    end
  end
  
  # Creates a channel of the type Beanstalk.
  def produce_channel(name=nil)
    Cod.beanstalk('localhost:11300', name)
  end

  context "anonymous tubes" do
    let!(:channel) { produce_channel() }
    before(:each) { clear_tube(channel.tube_name) }
    after(:each) { channel.close }
    
    it "should have simple message semantics" do
      # Split the channel into a write end and a read end. Otherwise
      # reading / writing from the channel will close the other end, 
      # leaving us unable to perform all operations.
      read = channel
      write = channel.dup

      write.put 'message1'
      write.put 'message2'

      read.should be_waiting
      read.get.should == 'message1'
      read.should be_waiting
      read.get.should == 'message2'

      read.should_not be_waiting
    end
    context "references" do
      it "should reconstruct from identifiers" do
        identifier = channel.identifier
        
        other_channel = identifier.resolve
        other_channel.put 'test'
        
        channel.get.should == 'test'
      end 
    end
  end
  context "named tubes" do
    let(:tube_name) { __FILE__ + ".named_tubes" }
    before(:each) { clear_tube(tube_name) }

    let!(:channel) { produce_channel(tube_name) }
    after(:each) { channel.close }
    
    it "should have simple message semantics" do
      channel.put 'test'
      
      # Construct another tube independently, the only common thing being the
      # tube_name
      other_channel = produce_channel(tube_name)
      other_channel.get.should == 'test'
    end 
  end
end