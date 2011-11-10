require 'spec_helper'

describe "Beanstalk transport" do
  context "'simple' tube" do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }

    xit "does simple messaging" do
      channel.put :test
      channel.get.should == :test
    end
    it "transmits line ends properly" do
      channel.put "\r\n"

      channel.get.should == "\r\n"
    end
  end
end