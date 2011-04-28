require 'spec_helper'

require 'cod/channel/tcp'

describe Cod::Channel::TCP do
  include Cod::Channel::TCP
  
  describe "#split_uri" do
    {
      'localhost:3000' => ['localhost', 3000], 
      ':3000'          => [nil, 3000], 
      '127.0.0.1:3001' => ['127.0.0.1', 3001]
    }.each do |input, expected|
      it "should parse #{input.inspect}" do
        split_uri(input).should == expected
      end 
    end

    it "should refuse when port number is missing" do
      expect { split_uri('localhost') }.to raise_error(ArgumentError)
    end 
  end
end