module Cod::Beanstalk
  class Channel    
    def initialize(tube_name, server_url='localhost:11300')
      @tube_name, @server_url = tube_name, server_url
    
      @body_serializer = Cod::SimpleSerializer.new
      @transport = Cod.tcp(server_url, Serializer.new)
      
      init_tube
    end
    
    def put(msg)
      pri   = 1
      delay = 0
      ttr   = 120
      body = @body_serializer.en(msg)
      
      answer, *rest = interact(:put, pri, delay, ttr, body)
      fail "#put fails, #{answer.inspect}" unless answer == :inserted
    end
  
    def get(opts={})
      answer, *rest = interact(:reserve)
      fail ":reserve fails, #{answer.inspect}" unless answer == :reserved
      
      id, msg = rest
      
      # We delete the job immediately, since we're being used as a channel, 
      # not as a queue:
      answer, *rest = interact(:delete, id)
      fail ":delete fails, #{answer.inspect}" unless answer == :deleted
      
      @body_serializer.de(StringIO.new(msg))
    end
  
    def close
      @transport.close
    end
  private 
    def init_tube
      answer, *rest = interact(:use, @tube_name)
      fail "#init_tube fails, #{answer.inspect}" unless answer == :using
      
      answer, *rest = interact(:watch, @tube_name)
      fail "#init_tube fails, #{answer.inspect}" unless answer == :watching
    end
    
    def interact(*msg)
      @transport.put msg
      @transport.get
    end
  end
end