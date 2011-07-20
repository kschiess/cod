require 'spec_helper'

require 'support/debug_proxy'

describe "TCP based channels" do
  let(:url) { 'localhost:20000'}
  let!(:server) { Cod.tcpserver(url) }
  let(:client) { Cod.tcp(url) }
  
  after(:each) { server.close; client.close }
  
  it "should provide simple messaging" do
    server.should_not be_waiting

    client.put :foo
    server.should be_waiting
    server.get.should == :foo
  end 
  describe "server part" do
    let(:second_client) { Cod.tcp(url) }
    it "should act as fan-in" do
      client.put 'test1'
      second_client.put 'test2'
      
      messages = 2.times.map { server.get }
      messages.should =~ %w(test1 test2)
    end 
    it "should not allow writing to" do
      expect {
        server.put 'test'
      }.to raise_error(Cod::Channel::CommunicationError)
    end 
  end
  describe "serialisation" do
    it "should transmit the client end to the server cleverly" do
      client.put client
      server_end = server.get

      server_end.put 'test'
      client.get.should == 'test'
    end 
    it "should refuse to transmit server ends" do
      # Transmitting a server makes no sense either. A socket can only 
      # be bound once. To transmit server channels, fork processes!
      expect {
        client.put server
      }.to raise_error(Cod::Channel::CommunicationError)
    end
  end

  context 'when linked by a proxy' do
    let(:from) { '127.0.0.1:33000' }
    let(:to)   { '127.0.0.1:33001' }

    let!(:debug_proxy) { DebugProxy.new(from, to) }

    let(:server) { Cod.tcpserver(to) } 
    let(:client) { Cod.tcp(from) }
    
    after(:each) {
      server.close
      client.close
      debug_proxy.kill
    }

    before(:each) { sleep 0.01 until debug_proxy.ready? }
    
    it "proxies requests" do
      client.put 'test'
      server.get.should == 'test'
    end 
    context 'when connection fails' do
      it "reconnects" do
        pending "Find a way to properly detect closed sockets"
        p :test1
        client.put 'test1'
        sleep 0.01 while debug_proxy.conn_count == 0
        debug_proxy.kill_all_connections
        p :test2
        client.waiting?
        client.put 'test2'
        
        p :rtest1
        server.get.should == 'test1'
        p :rtest2
        server.get.should == 'test2'
      end
      it "looses messages"  
    end
  end
end