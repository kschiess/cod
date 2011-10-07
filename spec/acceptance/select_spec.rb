require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cod.select" do
  describe 'on the channels (pipe)' do
    mlet(:read, :write) { Cod.pipe.split }
    after(:each) { read.close; write.close }
  
    it "returns simply true / false" do
      read.select(0.01).should == false
      
      write.put :test
      read.select(0.01).should == true
    end 
  end 
  describe '(timeout, groups)' do
    describe 'retains group form' do
      mlet(:read, :write) { Cod.pipe.split }
      after(:each) { read.close; write.close }
      
      it "(array)" do
        # TODO allow the creation of an additional pipe be optimized away.
        write.put :test
        result = Cod.select(nil, my_group: [read])

        result.should have_key(:my_group)
        result[:my_group].should =~ [read]
      end
      it "(single)" do
        write.put :test
        result = Cod.select(nil, my_group: read)

        result.should have_key(:my_group)
        result[:my_group].should == read
      end 
    end
    

    it "returns an empty hash when nothing is ready" do
      pipe = Cod.pipe

      pipe.select(0.01)
    end 
    
    it "allows Cod channels"
    it "allows IO descendants"
    it "has a default timeout of forever" 
  end 
end