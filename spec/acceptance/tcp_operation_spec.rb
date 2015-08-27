require 'spec_helper'

require 'tcp_proxy'

describe 'Cod TCP' do
  context "on localhost:12345" do
    # NOTE: By creating server and client in the wrong order (receiving end
    # after the sending send), we force the test code to handle cases where 
    # one or the other is not around yet. 
    #
    let(:client) { Cod.tcp('localhost:12345') }
    let(:server) { Cod.tcp_server('localhost:12345') }

    after(:each) { client.close; server.close }

    it "follows simple messaging semantics" do
      client.put :test
      server.get.assert == :test
    end 
    it "allows Cod.select for server" do
      client.put :test
      Cod.select(0.1, server).assert == server
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

        msg.assert == :test
        # channel is connected to client: 
        channel.put :answer

        client.get.assert == :answer
      end 
    end
    describe 'with Cod.select' do
      it "times out when no data is there" do
        Cod.select(0.01, test: server).assert == {}
      end 
    end
  end
  describe 'error handling' do
    describe 'when the client of a server goes away' do
      let(:client) { Cod.tcp('localhost:12345') }
      let(:server) { Cod.tcp_server('localhost:12345') }

      after(:each) { client.close; server.close }

      it "should remove it from its active connections" do
        client.put :test
        server.get.assert == :test
        
        expect { 
          client.close
          timeout(0.1) { server.get } rescue TimeoutError
        }.to change { server.connections }.by(-1)
      end 
    end
    describe 'when the connection goes down and comes back up' do
      let!(:client) { Cod.tcp('localhost:12345') }
      let!(:proxy)  { TCPProxy.new('localhost', 12345, 12346) }
      let!(:server) { Cod.tcp_server('localhost:12346') }

      after(:each) { client.close; server.close; proxy.close }
      
      it "throws a ConnectionLost error (Errno::ECONNRESET)" do
        client.put :test1
        server.get.assert == :test1
        
        proxy.drop_all
        
        expect { 
          client.put :test2 
          client.get
        }.to raise_error(Cod::ConnectionLost)
      end
      it "throws a ConnectionLost error (EOFError)" do
        client.put :test1
        server.get.assert == :test1
        
        proxy.drop_all
        
        expect { 
          client.get
        }.to raise_error(Cod::ConnectionLost)
      end
    end
    describe "when there is someone listening on the socket already" do
      let!(:server) { TCPServer.new('127.0.0.1', 54321) }
      after(:each) { server.close }
      
      it "errors out in the constructor" do
        expect {
          Cod.tcp_server('127.0.0.1:54321')
        }.to raise_error(Errno::EADDRINUSE)
      end 
    end
    describe "when the server isn't listening" do
      let(:client) { Cod.tcp('localhost:54321') }
      let(:server) { Cod.tcp_server('localhost:54321') }
      
      after(:each) { client.close; server.close }
      it "ignores messages (no error)" do
        client.put :test
        
        timeout(1) {
          server.get.assert == :test
        }
      end
      it "still may be selected" do
        Cod.select(0.01, client).assert be_nil
      end 
    end
    describe 'TCP connection closed before answer is read' do
      let(:client) { Cod.tcp('localhost:12345') }
      let(:server) { Cod.tcp_server('localhost:12345') }

      after(:each) { client.close; server.close }

      before(:each) { 
        client.put :test
        msg, chan = server.get_ext

        msg.assert == :test
        chan.put :answer

        # Closing the answer channel before it is read from
        chan.close
      }

      it "should not throw EOF error" do
        client.get.assert == :answer
      end 
    end
    describe 'TCP connection is read before it is written to' do
      let(:client) { Cod.tcp('localhost:12345') }

      after(:each) { client.close }
      
      it "should not throw EOFError" do
        begin
          # NOTE: Somewhat important for this test - the server hasn't been
          # instantiated and therefore no listening socket exists at this
          # point. This means that client will have no socket embedded -> 
          # hence the endless wait.
          timeout(0.01) do
            client.get
          end
        rescue Timeout::Error
        end
      end 
    end
  end
  describe 'regression' do
    describe '"pending messages loop" bug' do
      let(:client) { Cod.tcp('localhost:12345') }
      let(:server) { Cod.tcp_server('localhost:12345') }
      
      after(:each) { client.close; server.close }
      
      it "still returns even if nothing is on the wire" do
        client.put :test1
        client.put :test2
        
        msg, chan = server.get_ext
        msg.assert == :test1
        
        timeout(1) {
          msg, chan = server.get_ext
          msg.assert == :test2
        }
      end 
    end
  end
end