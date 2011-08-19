require 'spec_helper'

describe "TCP" do
  let!(:server) { TCPServer.new('127.0.0.1', 33000) }
  let!(:client) { TCPSocket.new('127.0.0.1', 33000) }
  let(:server_end) { server.accept }
  
  after(:each) { 
    server.close rescue nil
    client.close rescue nil
  }
  
  it "doesn't fail when sending data to a closed socket" do
    client.write('.')
    begin
      server_end.read_nonblock(100).should == '.'
    rescue Errno::EAGAIN
      retry
    end
    
    server_end.close
   
    # We can write to a closed socket without error
    client.write('.').should == 1

    # We get an exception if we try to read from it. 
    # Either EOFError or Errno::ECONNRESET.
    expect {
      client.read_nonblock(1)
    }.to raise_error
    
    # Selecting the socket will flag it as ready for write/read
    ready = IO.select([client], [client], [client])
    ready[0].should have(1).element
    ready[1].should have(1).element
  end 
  it "detects closing of a client socket when reading from it" do
    client.write('.')
    begin
      server_end.read_nonblock(100).should == '.'
    rescue Errno::EAGAIN
      retry
    end
    client.close

    # IO select doesn't know about closed client ends.
    ready = IO.select([server_end], [server_end], [server_end])
    ready[0].should have(1).element
    ready[1].should have(1).element
    
    # Writing doesn't fail.
    server_end.write('.')
    
    # But reading always should
    expect {
      server_end.read_nonblock(1)
    }.to raise_error # either Errno::ECONNRESET or EOFError
  end 
end