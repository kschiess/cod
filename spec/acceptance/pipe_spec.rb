require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cod::Pipe do
  context "when split into read & write" do
    slet(:pipe) { described_class.new }
    attr_reader :read, :write
    before(:each) { @read, @write = pipe.split }

    after(:each) { read.close; write.close }

    it "allows sending and receiving of message objects" do
      write.put [:an, :object]
      read.get.should == [:an, :object]
    end
    it 'transmits pipe objects intact' do
      other = described_class.new

      write.put other
      transmitted = read.get 

      transmitted.should == other
    end 
    it "doesn't raise on double close"  do
      pipe.close # already closed by split
      read.close # will be closed by test
    end
    
    # In a single process, you would split the pipe into its two ends. Splitting
    # makes the original object unusable, effectively acting like a close. 
    #
    describe 'splitting' do
      it 'returns the pipes ends' do
        write.pipe.w.write('.')
        read.pipe.r.read(1).should == '.'
      end
      it 'closes the pipe' do
        fds = pipe.pipe
        fds.r.should == nil
        fds.w.should == nil
      end
    end
  end
  
  # NOTE: no samples on using Cod.select on pipes, since select_spec does 
  # that extensively. 
  
  # In forked child processes, you inherit all pipes that you create before 
  # forking. Using them then (after the fork) for either read or write 
  # operations will dedicate them to that usage, closing the other part of the
  # pipe. 
  #
  describe 'read use' do
    let!(:pipe) { described_class.new }
    let!(:duplicate) { pipe.dup }
    
    after(:each) { pipe.close; duplicate.close }

    # Makes pipe writeonly and duplicate readonly
    before(:each) { 
      pipe.put :test
      duplicate.get }
    
    it 'closes the write part, raising when written to' do
      expect {
        duplicate.put :answer
      }.to raise_error(Cod::ReadOnlyChannel)
    end
    it 'allows further reading' do
      pipe.put :another_test
      duplicate.get
    end
  end 
  describe 'write use' do
    let!(:pipe) { described_class.new }
    let!(:duplicate) { pipe.dup }
    
    after(:each) { pipe.close; duplicate.close }

    # Makes pipe writeonly and duplicate readonly
    before(:each) { 
      pipe.put :test
      duplicate.get }

    it 'closes the read part, raising when read from' do
      expect {
        pipe.get
      }.to raise_error(Cod::WriteOnlyChannel)
    end
    it 'allows further writing' do
      pipe.put :another_test
      duplicate.get
    end
  end

  # You can replace the serializer on a pipe. 
  #
  context "when constructed with a serializer" do
    let(:serializer) { flexmock(:serializer) }
    slet(:pipe) { described_class.new(serializer) }
    
    before(:each) { serializer.should_receive(:en => 'serialized') }
    after(:each) { pipe.close }
    
    it 'uses the #de method to decode objects' do
      serializer.should_receive(:de => :return)
    
      r,w = pipe.split
      begin
        w.put :the_man
        r.get.should == :return 
      ensure
        r.close; w.close
      end
    end 
  end
  
end