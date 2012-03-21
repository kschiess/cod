module Cod
  
  # A serializer that implements a line by line wire protocol. Only strings
  # can be sent. An instance of this class can be used when constructing
  # any channel, turning it into a line oriented channel speaking a clear text
  # protocol. 
  #
  class LineSerializer
    # Turns a message into the wire format. 
    #
    # @param msg [#to_s] message to send
    # @return [String] buffer to be written to the wire
    #
    def en(msg)
      msg.to_s + "\n"
    end
    
    # Deserializes a message from the wire. 
    #
    # @param io [IO] the wire
    # @return [String]
    #
    def de(io)
      msg = io.gets
      return msg.chomp if msg
      raise EOFError
    end
  end
end