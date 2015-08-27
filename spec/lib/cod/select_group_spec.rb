require 'spec_helper'

describe Cod::SelectGroup do
  let(:group) {
    described_class.new(
      three: [1,2,3], 
      two: [1,2], 
      one: [1], 
      naught: 0)
  }
  describe '#keep_if' do
    it "iterates over the values, calling the block once per value element" do
      values = []
      group.keep_if { |e| values << e }
      
      values.sort.assert == [0, 1, 1, 1, 2, 2, 3]
    end
    it "keeps keys and values where the block returns true (e>2)" do
      group.keep_if { |e| e>2 }.keys.assert == [:three]
    end
    it "keeps keys and values where the block returns true (e>1)" do
      group.keep_if { |e| e>1 }.keys.assert == [:three, :two]
    end
    it "keeps keys and values where the block returns true (e>0)" do
      group.keep_if { |e| e>0 }.keys.assert == [:three, :two, :one]
    end
    it "keeps keys and values where the block returns true (true)" do
      group.keep_if { |e| true }.keys.assert == [:three, :two, :one, :naught]
    end 
  end
  describe '#values' do
    it "returns all values" do
      group.values.sort.assert == [0, 1, 1, 1, 2, 2, 3]
    end 
    it "allows transforming the values" do
      group.values { |e| e**2 }.sort.assert == [0, 1, 1, 1, 4, 4, 9]
    end 
  end
end