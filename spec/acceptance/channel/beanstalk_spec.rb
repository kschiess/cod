require 'spec_helper'

require 'timeout'

describe Cod::Channel::Beanstalk do
  let(:beanstalk_url) { 'localhost:11300' }
  
  # Removes all jobs from a beanstalk tube by name
  def clear_tube(name)
    conn = Beanstalk::Connection.new(beanstalk_url)
    
    loop do
      break unless conn.peek_ready
      job = conn.reserve
      job.delete
    end
    
    conn.close
  end
  
  # Creates a channel of the type Beanstalk.
  def produce_channel(name)
    Cod.beanstalk(beanstalk_url, name)
  end

  context "named tubes" do
    let(:tube_name) { __FILE__ + ".named_tubes" }
    before(:each) { clear_tube(tube_name) }

    let!(:channel) { produce_channel(tube_name) }
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
    it "should allow #get with timeout" do
      expect {
        channel.get(:timeout => 0.01)
      }.to raise_error(Cod::Channel::TimeoutError)
    end 
    context "references" do
      it "should resolve from an identifier (context is implicit)" do
        identifier = channel.identifier
        
        other_channel = identifier.resolve
        other_channel.put 'test'
        
        channel.get.should == 'test'
      end
      it "should allow sending a channel through a channel" do
        foo = produce_channel('foo')
        
        channel.put foo
        foo_dup = channel.get
        
        foo.put 'test'
        foo_dup.get.should == 'test'
      end 
    end
  end

  context "when used as transport for a Service" do
    let(:service_channel) { produce_channel('foobar') }
    before(:each) { clear_tube('foobar') }
    let(:client_channel) { produce_channel('client') }
    
    let(:service) { Cod::Service.new(service_channel) }
    let(:client)  { Cod::Client.new(service_channel, client_channel) }
    # after(:each) { service.close; client.close }
    
    it "should timeout on a server crash" do
      fork do service.one { exit } end

      expect {
        client.call
      }.to raise_error(Cod::Channel::TimeoutError)
      
      Process.waitall
    end
    context "regression" do
      it "should still allow notify sends (order of arguments between #notify and #call)" do
        fork do
          service.one { |m| m.should == :foo; 1 }
          service.one { |m| m.should == :foo }
          service.one { |m| m.should == :foo; 3 }
        end

        client.call(:foo).should == 1
        client.notify(:foo)
        client.call(:foo).should == 3

        Process.waitall
      end 
    end
  end
end