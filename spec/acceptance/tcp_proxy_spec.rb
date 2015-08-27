require 'spec_helper'

require 'tcp_proxy'

describe TCPProxy do
  let!(:client) { Cod.tcp('localhost:12345') }
  let(:client2) { Cod.tcp('localhost:12345') }
  let!(:server) { Cod.tcp_server('localhost:12346') }

  after(:each) { client.close; server.close }
  after(:each) { client2.close }
  
  let!(:proxy) { described_class.new('localhost', 12345, 12346) }
  after(:each) { proxy.close }
  
  it "implements a bidirectional tcp proxy" do
    timeout(5) do
      client.put :test
      msg, chan = server.get_ext 
      msg.assert == :test
      
      proxy.connections.size.assert == 1
      
      chan.put :antwoord
      client.get.assert == :antwoord
    end
  end 
  it "allows dropping connections" do
    client.put :test1
    server.get.assert == :test1
    
    proxy.block
    proxy.drop_all
    
    client.put :test2
    begin
      timeout(0.1) { server.get }
    rescue Timeout::Error
    end
    
    proxy.allow
    
    client2.put :test3
    server.get.assert == :test3
  end 
end