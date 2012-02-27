module Cod::Beanstalk

  # A channel based on a beanstalkd tube. A {#put} will insert messages into 
  # the tube, and a {#get} will fetch the next message that is pending on the
  # tube. 
  #
  # @note Beanstalk channels cannot currently be used in Cod.select. This is 
  #   due to limitations inherent in the beanstalkd protocol. We'll probably 
  #   try to get a patch into beanstalkd to change this. 
  #
  # @note If you embed a beanstalk channel into one of your messages, you will
  #   get a channel that connects to the same server and the same tube on the
  #   other end. This behaviour is useful for {Cod::Service}.
  #
  class Channel < Cod::Channel
    # All messages get inserted into the beanstalk queue as this priority. 
    JOB_PRIORITY = 0
    
    # Which tube this channel is connected to
    attr_reader :tube_name
    # Beanstalkd server this channel is connected to
    attr_reader :server_url
    
    def initialize(tube_name, server_url)
      super()
      @tube_name, @server_url = tube_name, server_url
    
      @body_serializer = Cod::SimpleSerializer.new
      @transport = connection(server_url, tube_name)
    end
    
    # Allow #dup on beanstalkd channels, resulting in a _new_ connection to
    # the beanstalkd server. 
    #
    def initialize_copy(other)
      super(other)
      initialize(other.tube_name, other.server_url)
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
    
    # @private
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
    
    # Like {#get}, read next message from the channel but reserve the right 
    # to put it back. This uses beanstalkds flow control features to be able
    # to control message flow in the case of exceptions and the like. 
    #
    # If the block given to this message raises an exception, the message 
    # is released unless a control command has been given. This means that
    # other workers on the same tube will get the chance to see the message. 
    #
    # If the block is exited without specifying a fate for the message, it
    # is deleted from the tube. 
    # 
    # @yield [Object, Cod::Beanstalk::Channel::Control]
    # @return the blocks return value
    #
    # @example All the flow control that beanstalkd allows
    #   channel.try_get { |msg, ctl|
    #     if msg == 1
    #       ctl.release # don't handle messages of type 1
    #     else
    #       ctl.bury    # for example
    #     end
    #   }
    #
    # @example Exceptions release the message
    #   # Will release the message and allow other connected channels to 
    #   # #get it.
    #   channel.try_get { |msg, ctl|
    #     fail "No such message handler"
    #   }
    #   
    #
    # @see Cod::Beanstalk::Channel::Control
    #
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
      attr_reader :msg_id
      
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
    # @private
    def _dump(level) # :nodoc:
      Marshal.dump(
        [@tube_name, @server_url])
    end
    # @private
    def self._load(str) # :nodoc:
      tube_name, server_url = Marshal.load(str)
      Cod.beanstalk(tube_name, server_url)
    end

    # ----------------------------------------------------- beanstalk commands
    # @private
    def bs_delete(msg_id)
      bs_command([:delete, msg_id], :deleted)
    end
    # @private
    def bs_release(msg_id)
      bs_command([:release, msg_id, JOB_PRIORITY, 0], :released)
    end
    # @private
    def bs_release_with_delay(msg_id, seconds)
      bs_command([:release, msg_id, JOB_PRIORITY, seconds], :released)
    end
    # @private
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