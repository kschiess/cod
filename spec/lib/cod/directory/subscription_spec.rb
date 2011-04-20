require 'spec_helper'

describe Cod::Directory::Subscription do
  let(:match_expr) { flexmock(:match_expr) }
  let(:channel)    { flexmock(:channel) }
  slet(:subscription) { described_class.new(match_expr, channel) }
  
  describe "#===" do
    it "should delegate to the match_expr's ===" do
      match_expr.should_receive(:===).and_return(:result).once
      
      subscription === 'foobar'
    end 
  end
  describe "#put" do
    it "should delegate to the channel" do
      channel.should_receive(:put).once
      
      subscription.put 'foobar'
    end 
  end
end