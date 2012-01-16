require 'spec_helper'

require 'tcp_proxy'

describe TCPProxy do
  let(:client) { Cod.tcp('localhost:12345') }
  let(:server) { Cod.tcp_server('localhost:12346') }
  after(:each) { client.close; server.close }
  
  let!(:proxy) { described_class.new('localhost', 12345, 12346) }
  after(:each) { proxy.close }
  
  it "implements a bidirectional tcp proxy" do
    timeout(5) do
      client.put :test
      msg, chan = server.get_ext 
      msg.should == :test
      
      proxy.should have(1).connections
      
      chan.put :antwoord
      client.get.should == :antwoord
    end
  end 
end