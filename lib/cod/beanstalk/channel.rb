module Cod::Beanstalk

  # NOTE: Beanstalk channels cannot currently be used in Cod.select. This is 
  # due to limitations inherent in the beanstalkd protocol. We'll probably 
  # try to get a patch into beanstalkd to change this. 
  #
  # NOTE: If you embed a beanstalk channel into one of your messages, you will
  # get a channel that connects to the same server and the same tube on the
  # other end. This behaviour is useful for Cod::Service.
  #
  class Channel < Cod::Channel
    def initialize(tube_name, server_url)
      @tube_name, @server_url = tube_name, server_url
    
      @body_serializer = Cod::SimpleSerializer.new
      @transport = connection(server_url, tube_name)
    end
    
    def put(msg)
      pri   = 1
      delay = 0
      ttr   = 120
      body = @body_serializer.en(msg)
      
      answer, *rest = @transport.interact([:put, pri, delay, ttr, body])
      fail "#put fails, #{answer.inspect}" unless answer == :inserted
    end
  
    def get(opts={})
      answer, *rest = @transport.interact([:reserve])
      fail ":reserve fails, #{answer.inspect}" unless answer == :reserved
      
      id, msg = rest
      
      # We delete the job immediately, since #get should be definitive.
      answer, *rest = @transport.interact([:delete, id])
      fail ":delete fails, #{answer.inspect}" unless answer == :deleted
      
      @body_serializer.de(StringIO.new(msg))
    end
  
    def close
      @transport.close
    end
    
    def to_read_fds
      fail "Cod.select not supported with beanstalkd channels.\n"+
        "To support this, we will have to extend the beanstalkd protocol."
    end
    
    # ---------------------------------------------------------- serialization
    def _dump(level) # :nodoc:
      Marshal.dump(
        [@tube_name, @server_url])
    end
    def self._load(str) # :nodoc:
      tube_name, server_url = Marshal.load(str)
      Cod.beanstalk(tube_name, server_url)
    end
    
  private 
    def connection(server_url, tube_name)
      conn = Cod.tcp(server_url, Serializer.new)

      begin
        answer, *rest = conn.interact([:use, tube_name])
        fail "#init_tube fails, #{answer.inspect}" unless answer == :using
      
        answer, *rest = conn.interact([:watch, tube_name])
        fail "#init_tube fails, #{answer.inspect}" unless answer == :watching
      rescue 
        conn.close
        raise
      end
      
      conn
    end
  end
end