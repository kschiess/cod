require 'spec_helper'

require 'tempfile'

describe "Bidirectional Pipes" do
  let!(:bidir) { Cod.bidir }
  after(:each) { bidir.close }
  
  it "is intended for forks" do
    fork do
      bidir.swap!
      bidir.put :test
    end
    
    Cod.select(0.1, bidir)
    bidir.get.should == :test
    Process.waitall
  end 
  
  describe "based on named sockets" do
    def gen_tmp_socket_path
      t = Tempfile.new('bidir')
      t.path.tap {
        t.close(true)
      }
    end
    
    let!(:path) { gen_tmp_socket_path }
    after(:each) { FileUtils.rm path }
    
    it 'allow transmission of channels trough channels (self)' do
      # This server is no different from any other ping/pong server in the
      # acceptance tests or even the examples. The relevant part here is that
      # processes are linked by socket name and that the channels are
      # transmitted through these sockets. 
      #
      fork do
        server = Cod.bidir_server(path)
        
        msg, back = server.get
        case msg
          when :ping
            back.put :pong
        else
          fail
        end
        
        back.close
      end
      
      sleep 0.01 until File.exist?(path)

      client = Cod.bidir_named(path)
      client.put [:ping, client]
      client.get.should == :pong

      Process.waitall.each do |pid, status|
        status.exitstatus.should == 0
      end
    end 
  end
end