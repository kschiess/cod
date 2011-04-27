require 'spec_helper'

describe "Kernel.at_fork" do
  it "should be called before every fork" do
    called = false
    at_fork { called = true }
    fork {}
    
    called.should == true
    Process.waitall
  end 
  it "should get old hook as argument" do
    called = []
    at_fork { called << :first }
    at_fork { |old| old.call; called << :second } 
    at_fork { |old| old.call; called << :third } 
    
    fork {}
    Process.waitall
    
    called.should == [:first, :second, :third]
  end 
end