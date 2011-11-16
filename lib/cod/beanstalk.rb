module Cod
  class Beanstalk
    
    class BeanstalkMessageSerializer
      def en(str)
        str
      end
      def de(io)
        # if context && bytes=context[:bytes]
        #   io.read(bytes)
        # else
        #   io.gets("\r\n")
        # end
      end
    end
    
    def initialize(tube_name, server_url='localhost:11300')
      @tube_name, @server_url = tube_name, server_url
      
      @body_serializer = SimpleSerializer.new
      @channel = Cod.tcp(server_url, BeanstalkMessageSerializer.new)
    end
    
    def put(msg)
      body = @body_serializer.en(msg)
      p body.bytesize
      priority = 0
      delay    = 0
      ttr      = 3600

      @channel.put format_cmd(:put, priority, delay, ttr, body.bytesize)
      @channel.put format_msg(body)
      
      case answer=@channel.get
        when /INSERTED \d+/
          # Job inserted, everything worked
        else
          fail answer
      end
    end
    
    def get(opts={})
      @channel.put format_cmd(:reserve)
      
      case answer=@channel.get
        when /RESERVED (?<id>\d+) (?<bytes>\d+)/
          # The second message that is read is the body: Only read bytes
          # bytes. 
          bytes = Integer($2)
          p bytes
          body = @channel.get(serializer: {bytes: bytes})
          p body
          return @body_serializer.de(StringIO.new(body))
      else
        fail answer
      end
    end
    
    def close
      @channel.close
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