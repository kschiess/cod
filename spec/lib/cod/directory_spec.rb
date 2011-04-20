require 'spec_helper'

describe Cod::Directory do
  let(:directory_channel) { flexmock(:directory_channel) }
  slet(:directory) { described_class.new(directory_channel) }
  describe "#close" do
    it "should close all resources" do
      directory_channel.should_receive(:close).once
      
      directory.close
    end 
  end
end