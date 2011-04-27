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

  context "(forked server)" do
    
    it "should implement simple call/response pattern" do
      fork do
        service.one { |message| 
          'bar' }
      end

      answer = client.call 'foo'
      answer.should == 'bar'
      
      Process.waitall
    end
    it "should implement #each (a looped one)" do
      pid = fork do
        service.each { |msg| msg }
      end

      10.times do |i|
        client.call(i).should == i
      end

      Process.kill('TERM', pid)
      Process.waitall
    end
    it "should implement async notify (a simple put)" do
      fork do
        service.one { |message| 'bar' }
      end

      client.notify('foo').should == nil
      achannel.should_not be_waiting
      
      Process.waitall
    end 
  end
  context "(forked client)" do
    it "should call the server method only once" do
      fork do
        client.call 'message'
      end
      
      calls = 0
      service.one { |msg| 
        msg.should == 'message' 
        calls += 1 }
        
      calls.should == 1
      
      Process.waitall
    end 
  end
end