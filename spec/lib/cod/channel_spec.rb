require 'spec_helper'

require 'cod/channel'

describe Cod::Channel do
  let(:channel) { described_class.new }
  describe '#interact' do
    it "should issue a put, followed by a get" do
      flexmock(channel).
        should_receive(:put).with(:msg).once.ordered.
        should_receive(:get).and_return(:result).once.ordered
      
      channel.interact(:msg).assert == :result
    end 
  end
end