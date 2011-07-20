require 'spec_helper'

describe "TCP" do
  it "doesn't fail when sending data to a closed socket" do
    server = TCPServer.new('127.0.0.1', 33000)
    client = TCPSocket.new('127.0.0.1', 33000)
    
    server_end = server.accept
    
    client.write('.')
    server_end.read_nonblock(100).should == '.'
    
    server_end.close
    client.write('.')
    expect {
      client.read_nonblock(1)
    }.to raise_error(Errno::ECONNRESET)
  end 
end