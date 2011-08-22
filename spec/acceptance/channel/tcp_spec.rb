require 'spec_helper'

require 'support/debug_proxy'

describe "TCP based channels" do
  let(:url) { 'localhost:20000'}
  let!(:server) { Cod.tcpserver(url) }
  let(:client) { Cod.tcp(url) }
  
  # A simple basic smoke test so that tests run in a defined state. 
  before(:each) { client.put :test; server.get.should == :test }
  
  after(:each) { server.close rescue nil }
  after(:each) { client.close rescue nil }
  
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
  describe 'close behaviour' do
    describe 'of serialized server end after the client has disconnected' do
      slet!(:server_end) { 
        client.put(client)
        server.get
      }
      after(:each) { server_end.close }
      
      # close the client, server end should notice. 
      before(:each) { client.close }
      
      it "has no messages waiting?" do
        server_end.waiting?.should == false
      end
      it "is disconnected" do
        server_end.connected?.should == false
      end 
    end
  end
end

describe 'TCP through proxy (33000 -> 33001)' do
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
      client.put 'test1'
      sleep 0.01 while debug_proxy.conn_count == 0
      debug_proxy.kill_all_connections
      client.waiting?
      client.put 'test2'
      
      server.get.should == 'test1'
      server.get.should == 'test2'
    end
    it "looses messages"  
  end
end
