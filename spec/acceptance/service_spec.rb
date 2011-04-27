require 'spec_helper'

describe Cod::Service do
  let!(:schannel) { Cod.pipe }
  let!(:achannel) { Cod.pipe }
  let!(:service)  { Cod::Service.new(schannel) }
  let!(:client)   { Cod::Client.new(schannel, achannel, 0.2) }
  
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
    it "should never return answers out of band" do
      fork do
        # This one takes too long - the client will not wait for this. 
        service.one { sleep(0.3); :foo } 
        # And this one takes only a short time - but the client might receive
        # the previous answer: 
        service.one { :bar } 
      end
      
      expect {
        client.call
      }.to raise_error(Cod::Channel::TimeoutError)
      
      client.call.should == :bar
      
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