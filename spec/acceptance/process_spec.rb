require 'spec_helper'

describe "Cod.process" do
  # class LineSerializer
  #   def en(msg)
  #   end
  #   def de(io)
  #     io.gets
  #   end
  # end
  let(:process) { Cod.process('true') }
  after(:each) { process.wait }
  
  let(:channel) { process.channel }
  
  it "throws ConnectionLost if the process goes away" do
    expect {
      p channel.get
    }.to raise_error(Cod::ConnectionLost)
  end 
end