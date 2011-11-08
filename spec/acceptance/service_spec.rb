require 'spec_helper'

describe "Cod services" do
  context "(a simple one)" do
    let(:service_channel) { Cod.pipe }
    let(:answer_channel) { Cod.pipe }
    
    attr_reader :pid
    before(:each) { 
      @pid = fork {
        server = Cod.service(service_channel)
        server.one { |request| request + 2 }}}
    after(:each) { 
      Process.kill(@pid)
      Process.wait(@pid) }
      
    after(:each) { service_channel.close; answer_channel.close }
      
    it "adds 2 with minimal ceremony" do
      service_channel.put [1, answer_channel]
      answer_channel.get.should == 3
    end 
  end
end