require 'spec_helper'

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
    it "should refuse to transmit client ends to foreign servers" do
      # Transmitting client to another server but the one that it's connected
      # to makes no sense. The user would expect to be able to read messages
      # from that server sent to it - but there is no such communication
      # channel.
      fail
    end 
    it "should refuse to transmit server ends" do
      # Transmitting a server makes no sense either. A socket can only 
      # be bound once. To transmit server channels, fork processes!
      fail
    end
  end
end