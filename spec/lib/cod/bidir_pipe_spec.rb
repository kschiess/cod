require 'spec_helper'

describe Cod::Bidir do
  let(:bidir) { described_class.new }
  after(:each) { bidir.close }
  
  describe '#interact' do
    it "calls #put, then #get" do
      flexmock(bidir).
        should_receive(:put).with(:msg).once.ordered.
        should_receive(:get).and_return(:ret).once.ordered
        
      bidir.interact(:msg).should == :ret
    end 
  end 
end