require 'spec_helper'

describe "Cod services" do
  Transport = Struct.new(:name, :init_block) do
    def init
      instance_eval(&init_block)
    end
    def server(&block); @server = block; end
    def client(&block); @client = block; end
    def get_server; @server.call; end
    def get_client; @client.call; end
  end
  
  def self.transport(name, &block)
    Transport.new(name, block)
  end
  
  [
    transport(:pipe) {
      server_pipe, client_pipe = Cod.pipe, Cod.pipe
      
      server { Cod.service(server_pipe) }
      client { Cod.client(server_pipe, client_pipe) }
    },
    transport(:tcp) {
      server_sock = Cod.tcp_server('localhost:12345')
      client_sock = Cod.tcp('localhost:12345')
      
      server { Cod.service(server_sock) }
      client { Cod.client(client_sock) }
    },
  ].each do |transport|
    describe "using #{transport.name}" do
      before(:each) { transport.init }
      
      context "(a simple one)" do
        let(:service) { transport.get_client }
        after(:each) { service.close }

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