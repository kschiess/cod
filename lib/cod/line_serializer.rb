module Cod
  class LineSerializer
    def en(msg)
      msg.to_s + "\n"
    end
    
    def de(io)
      msg = io.gets
      return msg.chomp if msg
      raise EOFError
    end
  end
end