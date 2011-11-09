require 'spec_helper'

describe "Cod services" do
  extend TransportHelper
    
  [
    transport(:pipe) {
      server_pipe, client_pipe = Cod.pipe, Cod.pipe
      
      server { Cod.service(server_pipe) }
      client { Cod.client(server_pipe, client_pipe) }
      close { server_pipe.close; client_pipe.close }
    },
    transport(:tcp) {
      server_sock = Cod.tcp_server('localhost:12345')
      client_sock = Cod.tcp('localhost:12345')
      
      server { Cod.service(server_sock) }
      client { Cod.client(client_sock) }
      close { server_sock.close; client_sock.close; p :close }
    },
  ].each do |transport|
    describe "using #{transport.name}" do
      before(:each) { transport.init }
      
      context "(a simple one)" do
        let(:service) { transport.get_client }
        after(:each) { transport.call_close }

        attr_reader :pid
        before(:each) { 
          @pid = fork {
            server = transport.get_server

            server.one { |request| request + 2 }}}
        after(:each) { 
          Process.kill('QUIT', @pid)
          Process.wait(@pid) }

        it "adds 2 with minimal ceremony" do
          service.call(1).should == 3
        end 
      end
    end
  end
end