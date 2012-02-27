module Cod::Beanstalk
  # Beanstalk services specialize for the beanstalk channels in that they
  # support a second service block argument, the control. Using this argument,
  # your service can refuse to accept a request or bury it for debugging
  # inspection.
  #
  # @example Additional block argument
  #   service.one { |request, control|
  #     control.retry_in(1) # release message with delay
  #   }
  # 
  class Service < Cod::Service
    def one(&block)
      @channel.try_get { |(rq, answer_chan), control| 
        result = if block.arity == 2
          block.call(rq, Control.new(control))
        else
          block.call(rq)
        end
        
        unless control.command_given?
          # The only way to respond to the caller is by exiting the block 
          # without giving metacommands.
          answer_chan.put result if answer_chan
        end
      }
    end
    
    class Control
      def initialize(channel_control)
        @channel_control = channel_control
      end
      
      # Releases the request and instructs the beanstalkd server to hand it
      # to us again in seconds seconds.
      #
      # @param [Fixnum] seconds 
      # @return [void]
      # 
      def retry_in(seconds)
        fail ArgumentError, 
          "#retry_in accepts only an integer number of seconds." \
          unless seconds.floor == seconds
            
        @channel_control.release_with_delay(seconds)
      end
      
      # Releases the request for immediate consumption by someone else.
      # 
      # @return [void]
      #
      def retry
        @channel_control.release
      end
      
      # Buries the message for later inspection. (see beanstalkd manual)
      # 
      # @return [void]
      #
      def bury
        @channel_control.bury
      end
      
      # Deletes the request. This is how you accept a request. 
      #
      # @return [void]
      #
      def delete
        @channel_control.delete
      end

      # Returns true if a flow control command has already been given as answer
      # to the current request. Multiple flow control commands are not allowed.
      #
      # @return [Boolean]
      #
      def command_issued?
        @channel_control.command_given?
      end
      
      def msg_id
        @channel_control.msg_id
      end
    end
    
    class Client < Cod::Service::Client
    end
  end
end