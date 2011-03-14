module Cod::Backends::Pipe
  class Factory
    def anonymous
      Mailbox.new
    end
  end
end