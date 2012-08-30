require 'spec_helper'

describe "Bidirectional Pipes" do
  let!(:bidir) { Cod.bidir_pipe }
  after(:each) { bidir.close }
  
  it "is intended for forks" do
    fork do
      bidir.swap!
      
      bidir.put :test
    end
    
    Cod.select(0.1, bidir)
    bidir.get.should == :test
    Process.waitall
  end 
end