module Cod::Beanstalk
  # This is a kind of beanstalk message middleware: It generates and parses
  # beanstalk messages from a ruby format into raw bytes. The raw bytes go
  # directly into the tcp channel that underlies the beanstalk channel. 
  #
  # Messages are represented as simple Ruby arrays, specifying first the
  # beanstalkd command, then arguments. Examples: 
  #   [:use, 'a_tube']
  #   [:delete, 123]
  #
  # One exception: The commands that have a body attached will be described
  # like so in protocol.txt: 
  #   put <pri> <delay> <ttr> <bytes>\r\n
  #   <data>\r\n
  #
  # To generate this message, just put the data where the bytes would be and
  # the serializer will do the right thing. 
  #   [:put, pri, delay, ttr, "my_small_data"]
  #
  # Results come back in the same way, except that the answers take the place
  # of the commands. Answers are always in upper case.
  #
  # Also see https://raw.github.com/kr/beanstalkd/master/doc/protocol.txt.
  #
  class Serializer
    def en(msg)
      cmd = msg.first
      
      if cmd == :put
        body = msg.last
        format(*msg[0..-2], body.bytesize) << format(body)
      else
        format(*msg)
      end
    end
    
    def de(io)
      str = io.gets("\r\n")
      raw = str.split
      
      cmd = convert_cmd(raw.first)
      msg = [cmd, *convert_args(raw[1..-1])]

      if [:ok, :reserved].include?(cmd)
        # More data to read:
        size = msg.last
        data = io.read(size+2)

        fail "No crlf at end of data?" unless data[-2..-1] == "\r\n"
        msg[-1] = data[0..-3]
      end
      
      msg
    end
    
  private
    # Joins the arguments with a space and appends a \r\n
    #
    def format(*args)
      args.join(' ') << "\r\n"
    end
    
    # Converts a beanstalkd answer like INSERTED to :inserted
    # 
    def convert_cmd(cmd)
      cmd.downcase.to_sym
    end
    
    # Converts an argument to either a number or a string, depending on
    # what it looks like. 
    # 
    # Example:
    #   convert_args(['1', 'a string']) # => [1, 'a string']
    #
    def convert_args(args)
      args.map { |e| 
        /^\d+$/.match(e) ? Integer(e) : e }
    end
  end
end