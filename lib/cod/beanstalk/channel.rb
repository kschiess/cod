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
    JOB_PRIORITY = 0
    
    def initialize(tube_name, server_url)
      @tube_name, @server_url = tube_name, server_url
    
      @body_serializer = Cod::SimpleSerializer.new
      @transport = connection(server_url, tube_name)
    end
    
    def put(msg)
      pri   = JOB_PRIORITY
      delay = 0
      ttr   = 120
      body = @body_serializer.en(msg)
      
      answer, *rest = @transport.interact([:put, pri, delay, ttr, body])
      fail "#put fails, #{answer.inspect}" unless answer == :inserted
    end
  
    def get
      id, msg = bs_reserve
      
      # We delete the job immediately, since #get should be definitive.
      bs_delete(id)

      deserialize(msg)
    end
  
    def close
      @transport.close
    end
    
    def to_read_fds
      fail "Cod.select not supported with beanstalkd channels.\n"+
        "To support this, we will have to extend the beanstalkd protocol."
    end
    
    # --------------------------------------------------------- service/client
    def service
      Service.new(self)
    end
    def client(answers_to)
      Service::Client.new(self, answers_to)
    end
    
    # -------------------------------------------------------- queue interface     
    def try_get 
      fail "No block given to #try_get" unless block_given?
      
      id, msg = bs_reserve
      control = Control.new(id, self)
      
      begin
        retval = yield(deserialize(msg), control)
      rescue Exception
        control.release unless control.command_given?
        raise
      ensure
        control.delete unless control.command_given?
      end
      
      return retval
    end
    
    # Holds a message id of a reserved message. Allows several commands to be
    # executed on the message. See #try_get.
    class Control # :nodoc:
      def initialize(msg_id, channel)
        @msg_id = msg_id
        @channel = channel
        @command_given = false
      end
        
      def command_given?
        @command_given
      end
      
      def delete
        @command_given = true
        @channel.bs_delete(@msg_id)
      end
      def release
        @command_given = true
        @channel.bs_release(@msg_id)
      end
      def release_with_delay(seconds)
        fail ArgumentError, "Only integer number of seconds are allowed." \
          unless seconds.floor == seconds
        
        @command_given = true
        @channel.bs_release_with_delay(@msg_id, seconds)
      end
      def bury
        @command_given = true
        @channel.bs_bury(@msg_id)
      end
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

    # ----------------------------------------------------- beanstalk commands
    def bs_delete(msg_id) # :nodoc:
      bs_command([:delete, msg_id], :deleted)
    end
    def bs_release(msg_id) # :nodoc:
      bs_command([:release, msg_id, JOB_PRIORITY, 0], :released)
    end
    def bs_release_with_delay(msg_id, seconds) # :nodoc:
      bs_command([:release, msg_id, JOB_PRIORITY, seconds], :released)
    end
    def bs_bury(msg_id)
      # NOTE: Why I need to assign a priority when burying I fail to
      # understand. Like a priority for rapture?
      bs_command([:bury, msg_id, JOB_PRIORITY], :buried)
    end
  private 
    def bs_reserve
      answer, *rest = bs_command([:reserve], :reserved)
      rest
    end
    def bs_command(cmd, good_answer)
      answer, *rest = @transport.interact(cmd)
      fail "#{cmd.first.inspect} fails, #{answer.inspect}" \
        unless answer == good_answer
      [answer, *rest]
    end
    
    def deserialize(msg)
      @body_serializer.de(StringIO.new(msg))
    end
  
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