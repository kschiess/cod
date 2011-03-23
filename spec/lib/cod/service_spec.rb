require 'spec_helper'

describe "Cod::Service" do
  let!(:channel)  { Cod.pipe }
  slet!(:service) { Cod::Service.new(channel.dup) }
  
  after(:each) { service.close }
  
  describe "#close" do
    it "should close the channel" do
      flexmock(service.incoming).should_receive(:close).at_least.once
      
      service.close
    end 
  end
end