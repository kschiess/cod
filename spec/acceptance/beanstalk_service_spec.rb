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
    describe '#retry_in(seconds)' do
      it "should call the service again in n seconds" do
        client.notify(:request)
        
        begin
          service.one { |request, control| control.retry_in(1) }
          service.one { |request| request.should == :request }
        rescue Timeout::Error
          fail "Test took too long."
        end
      end
    end
    describe '#retry' do
      it "should retry" do
        client.notify(:request)
        
        begin
          service.one { |request, control| control.retry }
          service.one { |request| request.should == :request }
        rescue Timeout::Error
          fail "Test took too long."
        end
      end
    end
    describe '#bury' do
      it "should bury the request" do
        client.notify(:request)
        
        begin
          service.one { |request, control| control.bury }
          timeout(0.1) do
            service.one { |request| }
          end
        rescue Timeout::Error
        end
      end
    end
  end
end