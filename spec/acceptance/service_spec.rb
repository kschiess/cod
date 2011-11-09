require 'spec_helper'

describe "Cod services" do
  Transport = Struct.new(:name, :init_block) do
    def init
      instance_eval(&init_block)
    end
    
    # Define a DSL method NAME that stores a block for later usage. You can 
    # call the block using VERB_NAME. 
    # 
    # Example: 
    #
    #   # in here
    #   define_block_storage :get, :bread
    #   # and in the definition of a transport: 
    #   bread { return :bread }
    #   # and then later on
    #   transport.get_bread
    def self.define_block_storage(verb, name)
      define_method(name) do |&block|
        @blocks ||= Hash.new
        @blocks[name] = block
      end
      define_method("#{verb}_#{name}") do
        @blocks[name].call
      end
    end

    define_block_storage :get, :server
    define_block_storage :get, :client
    define_block_storage :call, :close
  end
  
  def self.transport(name, &block)
    Transport.new(name, block)
  end
  
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