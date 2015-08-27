require 'spec_helper'

describe Cod::Beanstalk::Serializer, beanstalk: true do
  let(:serializer) { described_class.new }

  def en(*args)
    serializer.en(args)
  end
  def de(str)
    serializer.de(StringIO.new(str))
  end
  
  describe '#en' do
    it "encodes things simply to string" do
      en(:cmd, 1, "a_string").should == "cmd 1 a_string\r\n"
    end 
    it "encodes :put correctly" do
      en(:put, 1, 2, "A message").should == "put 1 2 9\r\nA message\r\n"
    end
  end
  describe '#de' do
    it "decodes simple one-line messages" do
      de("INSERTED 123\r\n").should == [:inserted, 123]
      de("EXPECTED_CRLF\r\n").should == [:expected_crlf]
    end 
    it "decodes RESERVED id bytes data" do
      de("RESERVED 123 9\r\nA message\r\n").
        should == [:reserved, 123, "A message"]
    end
    it "decodes OK bytes data" do
      de("OK 9\r\nA message\r\n").should == [:ok, 'A message']
    end 
    it "decodes arguments that contain numbers" do
      de("FUU fu123").
        should == [:fuu, 'fu123']
    end 
    
    describe 'when the io is eof?' do
      it "raises ConnectionLost" do
        expect {
          serializer.de(flexmock(:gets => nil))
        }.to raise_error(Cod::ConnectionLost)
      end
    end
  end
end