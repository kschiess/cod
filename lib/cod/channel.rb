module Cod
  module Channel
    # This is raised when you try to read from a channel you've already
    # written to or write to a channel that you've already read from. 
    #
    class DirectionError < StandardError; end
    
    # This is raised when a fatal communication error has occurred that 
    # Cod cannot recover from. 
    #
    class CommunicationError < StandardError; end
  end
end