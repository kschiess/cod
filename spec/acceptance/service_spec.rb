require 'spec_helper'

describe "Cod::Service" do
  extend TransportHelper

  # Helper method that allows shortcut definitions of servers.
  #
  def forked_service(transport, &block)
    pid = fork do
      server = transport.get_server
      # $stderr.reopen('/dev/null')

      block.call(server)
    end
    self.class.after(:each) { Process.kill('KILL', pid); Process.wait(pid) }
  end

  [
    transport(:pipe) {
      server_pipe, client_pipe = Cod.pipe, Cod.pipe
      
      server { server_pipe.service }
      client { server_pipe.client(client_pipe) }
      close { server_pipe.close; client_pipe.close }
    },
    transport(:tcp) {
      server_sock = Cod.tcp_server('localhost:12345')
      client_sock = Cod.tcp('localhost:12345')
      
      server { server_sock.service }
      client { server_sock.client(client_sock) }
      close { server_sock.close; client_sock.close }
    },
    transport(:beanstalk) {
      server_chan = Cod.beanstalk('server')
      client_chan = Cod.beanstalk('answer')
      
      server { server_chan.service }
      client { server_chan.client(client_chan) }
      close { server_chan.close; client_chan.close }
    }
  ].each do |transport|
    describe "using #{transport.name}s" do
      before(:each) { transport.init }
      after(:each) { transport.call_close }

      let(:service) { transport.get_client }
      
      context "adding two" do
        before(:each) { 
          forked_service(transport) do |server|
            server.one { |request| request + 2 }
          end
        }

        it "adds 2 with minimal ceremony" do
          service.call(1).should == 3
        end 
      end
      context "#notify" do
        let!(:done) { Cod.pipe } 
        before(:each) { 
          forked_service(transport) do |server|
            server.one { |rq| done.put rq ? :yes : :no }
          end
        }
        
        it "sends an asynch notification" do
          service.notify(true)
          done.get.should == :yes
        end 
      end
    end
  end

end