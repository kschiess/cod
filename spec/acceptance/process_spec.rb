require 'spec_helper'

describe "Cod.process" do
  after(:each) { process.wait }
  
  let(:channel) { process.channel }

  describe 'when starting a process that exits immediately' do
    let(:process) { Cod.process('true') }

    it "throws ConnectionLost if the process goes away" do
      expect {
        channel.get
      }.to raise_error(Cod::ConnectionLost)
    end 
  end
  describe "when starting 'ls'" do
    let(:process) { Cod.process('ls', Cod::LineSerializer.new) }
    
    it "reads output one line at a time" do
      messages = []
      
      loop do
        msg = channel.get rescue nil
        break unless msg
        messages << msg
      end
      
      messages.assert == `ls`.lines.map(&:chomp)
    end 
  end 
end