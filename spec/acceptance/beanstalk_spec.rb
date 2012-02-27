require 'spec_helper'

require 'tcp_proxy'

describe "Beanstalk transport" do
  include BeanstalkHelper
  
  describe 'construction through the Cod module' do
    it "takes one argument (tube_name)" do
      Cod.beanstalk('tube_name').close
    end 
    it "and optionally the server url" do
      Cod.beanstalk('tube_name', 'localhost:11300').close
    end
  end
  
  context "'simple' tube" do
    before(:each) { clear_tube('simple') }
    after(:each) { channel.close }

    let(:channel) { Cod.beanstalk('simple') }

    it "does simple messaging" do
      channel.put :test
      channel.get.should == :test
    end
    it "transmits line ends properly" do
      channel.put "\r\n"

      channel.get.should == "\r\n"
    end
    it "handles concurrency after being dupped with #dup" do
      # NOTE If this spec hangs, you just encountered the bug it is here to
      # fix.
      threads = 10.times.map do
        Thread.start(channel.dup) do |channel|
          10.times do
            channel.put :test
            channel.get
          end
        end
      end
      threads.each { |t| t.join }
    end 
    describe '#try_get' do
      before(:each) { channel.put :test; channel.put :other }
      it "reserves messages tentatively (control.release)" do
        channel.try_get { |msg, control|
          msg.should == :test
          # Releases the message, not consuming it.
          control.release
        }
        channel.get.should == :test
      end 
      it "consumes messages at the end of the block" do
        m = channel.try_get { |msg, control| msg }
        m.should == :test
        channel.get.should == :other
      end 
      it "allows release with delay" do
        channel.try_get { |msg, control|
          msg.should == :test
          # Releases the message, not consuming it.
          control.release_with_delay(1)
        }
        channel.get.should == :other
        channel.get.should == :test
      end
      it "releases the message when an exception occurs" do
        expect {
          channel.try_get { |msg, control| 
            raise Exception }
        }.to raise_error
        channel.get.should == :test
        channel.get.should == :other
      end  
      it "doesn't release when it cannot (command already issued)" do
        expect {
          channel.try_get { |msg, control| 
            control.delete
            raise Exception }
        }.to raise_error
        channel.get.should == :other
      end  
      it "buries messages" do
        channel.try_get { |msg, control| control.bury }
        # Currently no way to look at buried jobs: 
        channel.get.should == :other
      end 
    end
    
    context "and the 'other' tube" do
      before(:each) { clear_tube('other') }
      after(:each) { other.close }

      let(:other) { Cod.beanstalk('other') }

      it "transmits via named tubes" do
        other.put :foo
        channel.put :test
        channel.get.should == :test
        other.get.should == :foo
      end 
      it "allows transmission of beanstalk channels via beanstalk channels" do
        channel.put :test
        
        other.put channel
        clone = other.get
        
        clone.get.should == :test
      end 
    end
  end
  
  describe 'error behaviour' do
    before(:each) { clear_tube('errors') }
    
    let!(:proxy)  { TCPProxy.new('localhost', 11301, 11300) }
    let(:beanstalk) { Cod.beanstalk('errors', 'localhost:11301') }

    after(:each) { beanstalk.close }
    after(:each) { proxy.close }
    
    # Test the connection before testing error behaviour
    before(:each) { 
      beanstalk.put :test
      beanstalk.get.should == :test
    }
    
    describe 'when the connection to beanstalkd gets interrupted' do
      before(:each) { proxy.block }
      
      it "should throw a ConnectionLost error" do
        expect {
          proxy.drop_all
          beanstalk.get
        }.to raise_error(Cod::ConnectionLost)
      end 
    end 
  end
  
  describe '#select' do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }
    let(:predicate) { lambda { Cod.select(0.1, channel) } }

    it "raises an error" do
      expect(&predicate).to raise_error
    end 
    # NOTE: The 'problem' appears to be the following: Let's assume that we 
    # issue a RESERVE command with a timeout to beanstalk. Then select on the
    # socket that would receive an answer if there is one: 
    #   - reserve-with-timeout can only handle integer second amounts, which
    #     seeems wrong and would limit this implementation.
    #   - In the case where a job arrives within the timeout, we'll get a job
    #     answer. We need to hold this in memory until the code issues a #get.
    #     If it doesn't, it should somehow be released to beanstalk once again.
    #   - If no job arrives, the connection is still in a reserve-with-timeout
    #     and will block until the timeout expires. This is not what we want 
    #     with a select, it should be able to return quickly for other sockets
    #     and still accept commands for beanstalk channels.
    # 
    # We'd need a call that we can abort for this to work. This is not how 
    # beanstalkd currently works.
    #
    it "explains the problem" do
      begin
        predicate.call
      rescue => e
        e.message.should == "Cod.select not supported with beanstalkd channels.\n"+
          "To support this, we will have to extend the beanstalkd protocol."
      end
    end 
  end
end