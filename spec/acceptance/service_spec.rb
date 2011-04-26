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
  it "should implement #each (a looped one)" do
    pid = fork do
      service.each { |msg| msg }
    end
    
    10.times do |i|
      client.call(i).should == i
    end

    Process.kill('TERM', pid)
    Process.wait(pid)
  end
  it "should implement async notify (a simple put)" do
    pid = fork do
      service.one { |message| 'bar' }
    end

    client.notify('foo').should == nil
    achannel.should_not be_waiting
    
    Process.waitall
  end 
end