require 'spec_helper'

describe "Beanstalk transport" do
  context "'simple' tube" do
    let(:channel) { Cod.beanstalk('simple') }
    after(:each) { channel.close }

    it "does simple messaging" do
      channel.put :test
      channel.get.should == :test
    end
  end
end