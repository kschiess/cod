require 'spec_helper'

describe Cod::Beanstalk::Service do
  include BeanstalkHelper
  
  before(:each) { clear_tube('service'); clear_tube('client') }

  let!(:service_channel) { Cod.beanstalk('service') }
  let!(:answer_channel) { Cod.beanstalk('client') }
  
  after(:each) { service_channel.close; answer_channel.close }
  
  let(:client) { service_channel.client(answer_channel) }
  let(:service) { service_channel.service }
  
  describe 'exception handling' do
    describe '#retry_in(seconds, max_retries)' do
      it "should call the service again in n seconds" do
        client.notify(:request)
        
        begin
          service.one { |request, control| control.retry_in(1) }
          service.one { |request| request.should == :request }
        rescue Timeout::Error
          fail "Test took too long."
        end
      end
      it "should retry a few times" 
    end
    describe '#retry(max_retries)' do
      it "should retry a few times" 
    end
    describe '#bury' do
      it "should bury the request" 
    end
  end
end