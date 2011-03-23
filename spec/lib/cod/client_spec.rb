require 'spec_helper'

describe Cod::Client do
  let(:requests) { Cod.pipe }
  let(:answers)  { Cod.pipe }
  slet!(:client) { Cod::Client.new(requests, answers) } 

  after(:each) { client.close }
  
  describe "#close" do
    it "should close both channels" do
      # These are called twice, since we close the client in after(:each) as 
      # well. 
      flexmock(client.outgoing).should_receive(:close).at_least.once
      flexmock(client.incoming).should_receive(:close).at_least.once
      
      client.close
    end
  end
end