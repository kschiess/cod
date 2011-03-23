require 'spec_helper'

describe Cod::Channel::Pipe do
  slet!(:pipe) { described_class.new }
  after(:each) { pipe.close }
  
  describe "#identifier" do
    slet(:identifier) { pipe.identifier }
    
    it { should_not be_nil }
    it { should serialize }
  end
end