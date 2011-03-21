module Cod
  module Channel
    # This is raised when you try to read from a channel you've already
    # written to or write to a channel that you've already read from. 
    #
    class DirectionError < StandardError; end
  end
end