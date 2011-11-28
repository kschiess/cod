module Cod::Beanstalk
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
      
      def retry_in(seconds)
        fail ArgumentError, 
          "#retry_in accepts only an integer number of seconds." \
          unless seconds.floor == seconds
            
        @channel_control.release_with_delay(seconds)
      end
    end
    
    class Client < Cod::Service::Client
    end
  end
end