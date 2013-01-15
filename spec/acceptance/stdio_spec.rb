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
    it "allows killing the process" do
      process = Cod.process('cat', LineSerializer.new)

      process.kill
      process.wait
    end 
  end
  describe 'Cod.stdio' do
    let!(:child_chan) { Cod.bidir(LineSerializer.new) }

    def redirected_child
      fork do
        o = child_chan.other
        
        STDOUT.reopen(o)
        STDIN.reopen(o)
        o.close
        
        yield
      end
    end
    
    after(:each) { Process.waitall }
    
    it "has a working spec setup" do
      redirected_child do
        # gets executed in child
        puts Marshal.dump(:test)
      end
      
      child_chan.get.should == :test
    end
    it "links a process' stdin/stdout to a channel" do
      redirected_child do
        stdio = Cod.stdio(LineSerializer.new)
        
        stdio.put :test
      end
      
      child_chan.get.should == :test
    end
    it "links the channel up correctly" do
      stdio = Cod.stdio
      stdio.r.should == $stdin
      stdio.w.should == $stdout
    end 
  end
end