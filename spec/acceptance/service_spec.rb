require 'spec_helper'

describe "Cod services" do
  Transport = Struct.new(:name, :service_channel, :answer_channel) do
    def service_on(&block)
      self.service_channel = block
    end
    def answer_on(&block)
      self.answer_channel = block
    end
  end
  def self.transport(name, &block)
    Transport.new(name).tap { |transport| transport.instance_eval(&block) }
  end
  
  [
    transport(:pipe) {
      service_on { Cod.pipe }
      answer_on { Cod.pipe }
    }, 
    transport(:tcp) { 
      service_on { Cod.tcp('localhost:12345') }
      answer_on { Cod.tcp_server('localhost:12345') }
    }
  ].each do |transport|
    describe "using #{transport.name}" do
      let!(:service_channel) { transport.service_channel[] }
      let!(:answer_channel) { transport.answer_channel[] }
      
      after(:each) { service_channel.close; answer_channel.close }

      context "(a simple one)" do
        let(:service) { Cod.service_client(service_channel, answer_channel) }

        attr_reader :pid
        before(:each) { 
          @pid = fork {
            server = Cod.service(service_channel)
            server.one { |request| request + 2 }}}
        after(:each) { 
          Process.kill('QUIT', @pid)
          Process.wait(@pid) }

        after(:each) { service_channel.close; answer_channel.close }

        it "adds 2 with minimal ceremony" do
          service.call(1).should == 3
        end 
      end
    end
  end
end