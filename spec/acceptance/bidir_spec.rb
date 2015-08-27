
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
    fail "AF: return is not == :test" unless bidir.get == :test
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
    after(:each) { FileUtils.rm path rescue nil }
    
    def waitall_assert
      Process.waitall.each do |pid, status|
        fail "AF: exitstatus is not 0" unless status.exitstatus == 0
      end
    end
    
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
      client.get.assert == :pong

      waitall_assert
    end 
    it 'allow transmission of other channels' do
      fork do
        server = Cod.bidir_server(path)

        # other will contain the channel we send through the named channel.
        other, back = server.get_ext
        other.put :test
        
        back.close
      end
      
      sleep 0.01 until File.exist?(path)

      client = Cod.bidir_named(path)
      other = Cod.bidir
      
      client.put other
      other.get.assert == :test

      waitall_assert
    end 
  end
end