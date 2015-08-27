require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cod.select" do
  describe 'on the channels (pipe)' do
    let(:split) { Cod.pipe.split }
    let(:read) { split.read }
    let(:write) { split.write }
      
    it "returns simply true / false" do
      read.select(0.01).assert == false
      
      write.put :test
      read.select(0.01).assert == true
    end 
  end 
  describe '(timeout, groups)' do
    describe 'retains group form' do
      let(:split) { Cod.pipe.split }
      let(:read) { split.read }
      let(:write) { split.write }

      after(:each) { read.close; write.close }
      
      it "(array)" do
        # TODO allow the creation of an additional pipe be optimized away.
        write.put :test
        result = Cod.select(nil, my_group: [read])
        
        result.assert have_key(:my_group)
        result[:my_group].assert == [read]
      end
      it "(single)" do
        write.put :test
        result = Cod.select(nil, my_group: read)

        result.assert have_key(:my_group)
        result[:my_group].assert == read
      end 
    end

    it "returns an empty hash when nothing is ready" do
      pipe = Cod.pipe

      pipe.select(0.01)
    end 

    describe 'allowed values' do
      let(:split) { Cod.pipe.split }
      let(:read) { split.read }
      let(:write) { split.write }

      after(:each) { read.close; write.close }

      it "allows Cod channels" do
        write.put :test
        Cod.select(0.1, foo: read).keys.assert == [:foo]
      end
      it "allows IO descendants" do
        r,w = IO.pipe
        w.write('.')
        Cod.select(0.1, foo: r).keys.assert == [:foo]
        r.close; w.close
      end
    end
  end 
end