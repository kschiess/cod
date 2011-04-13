module Cod
  class Service::Call
    attr_reader :message
    attr_reader :channel
    
    def initialize(message, channel)
      @message, @channel = message, channel
    end
    
    def response(message)
      Service::Response.new(message)
    end
  end
end