require 'spec_helper'

describe "Beanstalk transport" do
  context "'simple' tube" do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }

    it "does simple messaging" do
      pending "Proper serializer"
      channel.put :test
      channel.get.should == :test
    end
    it "transmits line ends properly" do
      pending "Proper serializer"
      channel.put "\r\n"

      channel.get.should == "\r\n"
    end
  end
end