require 'spec_helper'

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
      xit "consumes messages at the end of the block" do
        m = channel.try_get { |msg, control| msg }
        m.should == :test
        channel.get.should == :other
      end 
      xit "allows release with delay" do
        channel.try_get { |msg, control|
          msg.should == :test
          # Releases the message, not consuming it.
          control.release_with_delay(1)
        }
        channel.get.should == :other
        channel.get.should == :test
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
  
  describe '#select' do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }
    let(:predicate) { lambda { Cod.select(0.1, channel) } }

    it "raises an error" do
      expect(&predicate).to raise_error
    end 
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