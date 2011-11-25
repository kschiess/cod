require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Cod TCP' do
  # NOTE: By creating server and client in the wrong order (receiving end
  # after the sending send), we force the test code to handle cases where 
  # one or the other is not around yet. 
  #
  let(:client) { Cod.tcp('localhost:12345') }
  let(:server) { Cod.tcp_server('localhost:12345') }
  
  after(:each) { client.close; server.close }
  
  it "follows simple messaging semantics" do
    client.put :test
    server.get.should == :test
  end 
  it "correctly shuts down the background thread" do
    client.put :test
    
    expect {
      client.close
    }.to change { Thread.list.size }.by(-1)
  end 
  
  describe 'server#get_ext' do
    it "returns a tuple of <msg, channel>" do
      client.put :test
      msg, channel = server.get_ext
      
      msg.should == :test
      # channel is connected to client: 
      channel.put :answer

      client.get.should == :answer
    end 
  end
  describe 'with Cod.select' do
    it "times out when no data is there" do
      Cod.select(0.01, test: server).should == {}
    end 
  end
  describe 'error handling' do
    it "handles a socket that already exists (bind error)"
    it "handles when the server socket isn't listening (yet)"
    it "handles interruption of the connection" 
    
    describe 'TCP connection closed before answer is read' do
      before(:each) { 
        client.put :test
        msg, chan = server.get_ext

        msg.should == :test
        chan.put :answer

        # Closing the answer channel before it is read from
        chan.close
      }

      it "should not throw EOF error" do
        client.get.should == :answer
      end 
      it "should work on the underlaying level" do
        server = TCPServer.new('localhost', 11300)
        client = TCPSocket.new('localhost', 11300)

        chan = server.accept
        
        answer_chan = chan.dup
        answer_chan.write('a'*10)
        answer_chan.close

        client.read_nonblock(100).should == 'a'*10
        
        chan.close
        server.close
        client.close
      end 
    end
    
  end
end