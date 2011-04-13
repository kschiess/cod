module Cod
  class Service::Response
    attr_reader :message
    
    def initialize(message)
      @message = message
    end
  end
end