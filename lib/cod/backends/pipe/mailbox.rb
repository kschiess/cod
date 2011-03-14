
module Cod::Backends::Pipe
  class Mailbox
    attr_reader :read_end, :write_end
    attr_reader :waiting
    def initialize
      @read_end, @write_end = IO.pipe
      @waiting = Array.new
    end
    
    def write(msg)
      # Encode size of the message and the message itself. 
      # TODO refactor this into a message class
      buffer = [msg.size].pack('l') + msg
      write_end.write(buffer)
    end
    
    def waiting?
      process_nonblock
      not waiting.empty?
    end
    
    def read
      loop do
        process_nonblock
        
        return waiting.shift if waiting?
      end
      
      fail "NEVER REACHED"
    end

  private
    def process_nonblock
      buffer = read_end.read_nonblock(2**20)
    
      while buffer.size > 0
        size = buffer.slice!(0,4).unpack('l').first
        fail "BUG: size too big" if size>buffer.size
        fail "BUG: size too small" if size <= 0
        waiting << buffer.slice!(0...size)
      end
    rescue Errno::EAGAIN
      # read_end is not ready, just ignore.
    end
  end
end