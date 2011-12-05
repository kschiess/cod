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
      # pid, channel = Cod.process('tee debug.log | cat', LineSerializer.new)
      pid, channel = Cod.process('cat', LineSerializer.new)
      
      channel.put :test
      channel.get.should == :test

      channel.close
      
      Process.wait(pid)
    end
    it "does line counting (silly)" do
      pid, channel = Cod.process('wc -l', StringLineSerializer.new)
      
      channel.put 'line1'
      channel.put 'line2'
      channel.put 'line3'
      
      channel.terminate
      
      Integer(channel.get).should == 3
      channel.close
      
      Process.wait(pid)
    end 
  end
end