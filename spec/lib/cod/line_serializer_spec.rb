require 'spec_helper'

describe Cod::LineSerializer do
  let(:serializer) { described_class.new }
  
  describe '#en(msg)' do
    def en(msg)
      serializer.en(msg)
    end
    
    it "should encode by appending newlines" do
      en('foo').should == "foo\n"
    end 
  end
  describe '#de(io)' do
    def de(str)
      io = StringIO.new(str)
      messages = []
      loop do
        msg = serializer.de(io)
        break unless msg
        
        messages << msg
      end
      
      messages
    rescue EOFError
      messages
    end
    
    it "should decode one line at a time" do
      de("foo\nbar\n").should == ['foo', 'bar']
    end 
  end
end