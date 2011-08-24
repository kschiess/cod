require 'spec_helper'

describe Cod::Directory::Subscription do
  let(:match_expr) { flexmock(:match_expr) }
  let(:channel)    { flexmock(:channel) }
  slet(:subscription) { described_class.new(match_expr, channel, 'id') }
  
  # Defaults for channel
  before(:each) { channel.
    should_receive(:put).by_default
  }
  
  describe "#===" do
    it "should delegate to the match_expr's ===" do
      match_expr.should_receive(:===).and_return(:result).once
      
      subscription === 'foobar'
    end 
  end
  describe "#put" do
    before(:each) { channel.should_receive(:put).by_default }
    
    it "should delegate to the channel" do
      channel.should_receive(:put).once
      
      subscription.put 'foobar'
    end 
    it "should send <ping_id, message>" do
      channel.should_receive(:put).with([subscription.identifier, :message])
      
      subscription.put :message
    end
    it "should start the countdown" do
      flexmock(subscription.countdown).should_receive(:start).once
      
      subscription.put :test
    end 
  end
  describe '#ping' do
    it "should stop the countdown" do
      flexmock(subscription.countdown).should_receive(:stop).once
      
      subscription.ping
    end
  end

  describe 'when no ping arrives for a long time' do
    let(:last_reset) { Time.now }
    let(:late) { last_reset + 40*60 }
    before(:each) { 
      subscription.put :test 
    }
    
    it "goes stale" do
      subscription.should be_stale(late)
    end
    it "doesn't go stale when a ping arrives late" do
      subscription.ping(late)
      subscription.countdown.should be_elapsed(late)
      subscription.should_not be_stale(late)
    end
  end
  describe 'when put in a set' do
    let(:a) { described_class.new(match_expr, channel, '1') }
    let(:b) { described_class.new(match_expr, channel, '2') }
    
    let(:s) { Set.new }
    
    before(:each) { 
      s << a
      s << b }
    it "behaves correctly" do
      s.should include(a)
      s.should include(b)
      s.should have(2).elements

      s << a
      s << b
      
      s.should include(a)
      s.should include(b)
      s.should have(2).elements
    end 
    it "consolidates elements that have the same identifier" do
      s << described_class.new(match_expr, channel, '1')
      s << described_class.new(match_expr, channel, '2')
      
      s.should have(2).elements
    end 
  end
end