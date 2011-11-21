module Cod::Beanstalk
  class Channel    
    def initialize(tube_name, server_url='localhost:11300')
      @tube_name, @server_url = tube_name, server_url
    
      @body_serializer = Cod::SimpleSerializer.new
      @transport = Cod.tcp(server_url, Serializer.new)
    end
  
    def put(msg)
      pri   = 1
      delay = 0
      ttr   = 120
      body = @body_serializer.en(msg)
      
      @transport.put [:put, pri, delay, ttr, body]
      
      answer=@transport.get
      unless answer.first == :inserted
        fail "#put fails, #{answer.inspect}"
      end
    end
  
    def get(opts={})
      @transport.put [:reserve]
      
      answer=@transport.get
      unless answer.first == :reserved
        fail ":reserve fails, #{answer.inspect}"  
      end
      # assert: answer.first == :reserved
      
      _, id, msg = answer
      
      # We delete the job immediately, since we're being used as a channel, 
      # not as a queue:
      @transport.put [:delete, id]
      answer=@transport.get
      unless answer.first == :deleted
        fail ":delete fails, #{answer.inspect}"
      end
      
      @body_serializer.de(StringIO.new(msg))
    end
  
    def close
      @transport.close
    end
  private 
    def format_cmd(command, *args)
      format_msg [command, *args].join(' ')
    end
    def format_msg(message)
      message + "\r\n"
    end
  end
end