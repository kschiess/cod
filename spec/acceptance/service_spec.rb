require 'spec_helper'

describe Cod::Service do
  let!(:schannel) { Cod.pipe }
  let!(:achannel) { Cod.pipe }
  let!(:service)  { Cod::Service.new(schannel) }
  let!(:client)   { Cod::Client.new(schannel, achannel) }
  
  after(:each) { 
    service.close
    client.close
  }
  
  it "should implement simple call/response pattern" do
    pid = fork do
      service.one { |message| 'bar' }
    end
    
    answer = client.call 'foo'
    answer.should == 'bar'

    Process.wait(pid)
  end
end