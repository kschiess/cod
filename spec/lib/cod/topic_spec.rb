require 'spec_helper'

describe Cod::Topic do
  include FlexMock::ArgumentTypes
  
  context "using mocked channels" do
    def cmd(cmd)
      on { |e| e.first == cmd }
    end

    let(:directory) { flexmock(:directory) }
    let(:incoming)  { flexmock(:incoming) }
    slet(:topic) { described_class.new('topic_string', directory, incoming) }

    # Defaults for directory and incoming mock.
    before(:each) { 
      directory.
        should_receive(:put).by_default
      incoming.
        should_receive(:get).by_default
    }

    describe "#close" do
      it "should close both channels" do
        [directory, incoming].each { |chan| 
          chan.should_receive(:close).once }

        directory.should_receive(:put)

        topic.close
      end 
    end
    describe '#get' do
      it "sends back a ping" do
        directory.
          should_receive(:put).with(cmd(:subscribe)).
          should_receive(:put).with(cmd(:ping)).once

        topic.get
      end 
    end
  end
  
  context "using real channels" do
    let!(:directory) { Cod.pipe }
    let!(:incoming)  { Cod.pipe }
    
    
    slet!(:topic) { described_class.new(
      'topic_string', 
      directory.dup, incoming.dup, 
      :renew => 10) }

    after(:each) { directory.close; incoming.close }
    after(:each) { topic.close }
        
    describe '#get' do
      it "raises TimeoutError after :timeout seconds" do
        expect {
          topic.get(:timeout => 0.1)
        }.to raise_error(Cod::Channel::TimeoutError)
      end 
      context "after the renew_countdown elapses" do
        let(:countdown) { flexmock(:countdown, 
          :run_time => 10, 
          :elapsed? => true) }
        before(:each) { flexmock(topic, :renew_countdown => countdown) }

        it "sends another subscription" do
          flexmock(topic).
            should_receive(:renew_subscription).once

          topic.get(:timeout => 0.1) rescue Cod::Channel::TimeoutError
        end 
      end
    end
  end
end