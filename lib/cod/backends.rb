
module Cod
  module Backends
  end
  
  class << self # class methods
    # Returns the backend for scope. 
    #
    def backend(scope)
      Cod::Backends::Pipe::Factory.new
    end
  end
end

require 'cod/backends/pipe'