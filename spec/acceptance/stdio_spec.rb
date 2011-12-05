require 'spec_helper'

describe "StdIO channels" do
  class LineSerializer
    def en(msg)
      Marshal.dump(msg) + "\n"
    end
    def de(io, &block)
      str = io.gets.chomp
      Marshal.load(str, block)
    end
  end
  class StringLineSerializer
    def en(msg)
      msg + "\n"
    end
    def de(io)
      io.gets.chomp
    end
  end
  describe 'Cod.process' do
    it "allows line-wise communication with any command" do
      process = Cod.process('cat', LineSerializer.new)
      channel = process.channel
      
      channel.put :test
      channel.get.should == :test

      process.terminate
      process.wait
    end
    it "does line counting (silly)" do
      process = Cod.process('wc -l', StringLineSerializer.new)
      channel = process.channel
      
      channel.put 'line1'
      channel.put 'line2'
      channel.put 'line3'
      
      process.terminate
      
      Integer(channel.get).should == 3
      channel.close
      
      process.wait
    end 
  end
end