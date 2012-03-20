require 'spec_helper'

describe "Cod.process" do
  let(:process) { Cod.process('true') }
  after(:each) { process.wait }
  
  let(:channel) { process.channel }
  
  it "throws ConnectionLost if the process goes away" do
    expect {
      channel.get
    }.to raise_error(Cod::ConnectionLost)
  end 
end