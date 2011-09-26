require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cod::Pipe do
  slet(:pipe) { described_class.new }
  attr_reader :read_end, :write_end
  before(:each) { @read_end, @write_end = pipe.split }

  after(:each) { pipe.close }
  
  it "allows sending and receiving of message objects" do
    write.put [:an, :object]
    read.get.should == [:an, :object]
  end
  it 'transmits pipe objects intact' do
    read, write = pipe.split
    
    other = described_class.new

    write.put other
    transmitted = read.get 

    transmitted.should == other
  end 
  
  # In a single process, you would split the pipe into its two ends. Splitting
  # makes the original object unusable, effectively acting like a close. 
  #
  describe 'splitting' do
    it 'returns the pipes ends' 
    it 'closes the pipe' 
  end
  
  # In forked child processes, you inherit all pipes that you create before 
  # forking. Using them then (after the fork) for either read or write 
  # operations will dedicate them to that usage, closing the other part of the
  # pipe. 
  #
  describe 'read use' do
    it 'closes the read part, raising when read from'
    it 'allows further reading'
  end 
  describe 'write use' do
    it 'closes the write part, raising when written to'
    it 'allows further reading'  
  end

  # You can replace the serializer on a pipe. 
  #
  context "when constructed with a serializer" do
    let(:serializer) { flexmock(:serializer) }
    slet(:pipe) { described_class.new(serializer) }
    
    before(:each) { serializer.should_receive(:en => 'serialized') }
    
    it 'uses the #de method to decode objects' do
      serializer.should_receive(:de => :return)
      
      pipe.put :the_man
      pipe.get.should == :return 
    end 
  end
  
end