require 'spec_helper'

describe "Beanstalk transport" do
  context "'simple' tube" do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }

    it "does simple messaging" do
      channel.put :test
      channel.get.should == :test
    end
    it "transmits line ends properly" do
      channel.put "\r\n"

      channel.get.should == "\r\n"
    end
    context "and the 'other' tube" do
      let(:other) { Cod.beanstalk('other') }
      after(:each) { other.close }

      it "transmits via named tubes" do
        other.put :foo
        channel.put :test
        channel.get.should == :test
        other.get.should == :foo
      end 
    end
  end
  
  describe '#select' do
    it "blocks until a message becomes available" 
    it "returns when timeout is reached" 
    it "allows mixed requests" 
  end
end