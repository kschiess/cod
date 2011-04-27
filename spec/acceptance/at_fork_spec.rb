
require 'spec_helper'

describe "At fork behaviour" do
  it "should only weakly reference the context" do
    ref = WeakRef.new(Cod.context)
    
    Cod.reset
    ObjectSpace.garbage_collect
    
    # Check if indeed it has been garbage collected
    expect {
      ref.inspect
    }.to raise_error(WeakRef::RefError)
  end 
end