require 'spec_helper'

describe Cod::BidirPipe do
  let(:bidir_pipe) { described_class.new }
  after(:each) { bidir_pipe.close }
  
  describe '#interact' do
    it "calls #put, then #get" do
      flexmock(bidir_pipe).
        should_receive(:put).with(:msg).once.ordered.
        should_receive(:get).and_return(:ret).once.ordered
        
      bidir_pipe.interact(:msg).should == :ret
    end 
  end 
end