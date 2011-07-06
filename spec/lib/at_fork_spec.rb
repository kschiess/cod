require 'spec_helper'

describe "Kernel.at_fork" do
  before(:each) { 
    Kernel.at_fork_parent.replace([])
    Kernel.at_fork_child.replace([]) 
  }
  
  it "should be called before every fork" do
    called = false
    at_fork { called = true }
    fork {}
    
    called.should == true
    Process.waitall
  end 
  it "should get called in order of definition" do
    called = []
    at_fork { called << :first }
    at_fork { called << :second } 
    at_fork { called << :third } 
    
    fork {}
    Process.waitall
    
    called.should == [:first, :second, :third]
  end 
  describe ":parent" do
    it "should be default" do
      pid = nil
      at_fork(:parent) { pid = Process.pid }
      
      fork {}
      Process.waitall
      
      pid.should == Process.pid
    end
  end
  describe ":child" do
    it "should execute first thing in the child" do
      r,w = IO.pipe
      pid = nil
      
      at_fork(:child) { w.write(Marshal.dump(Process.pid)) }

      fork {}
      Process.waitall
      
      pid = Marshal.load(r)
      pid.should_not == Process.pid
      pid.should > 0
    end 
  end
end