
module Cod::Backends::Pipe
  class Mailbox
    attr_reader :read_end, :write_end
    def initialize
      @read_end, @write_end = IO.pipe
    end
    
    def write(msg)
      write_end.write(msg)
    end
    
    def data_waiting?
      true
    end
    
    def read
      buf = read_end.read_nonblock(1024)
    end
  end
end