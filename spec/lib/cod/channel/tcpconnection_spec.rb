require 'spec_helper'

describe Cod::Channel::TCPConnection do
  let(:tcp) { described_class.new('localhost:12345') }
  describe '#close' do
    it "closes the whole pool" do
      flexmock(tcp.connection_pool).
        should_receive(:close).once
      
      tcp.close
    end 
  end
end