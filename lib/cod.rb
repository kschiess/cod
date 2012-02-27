require 'stringio'

# The core concept of Cod are 'channels'. (see {Cod::Channel::Base}) You can
# create such channels on top of the various transport layers. Once you have
# such a channel, you #put messages into it and you #get messages out of it.
# Messages are retrieved in FIFO manner, making channels look like a
# communication pipe most of the time. 
#
# Cod also brings a few abstractions layered on top of channels: You can use
# channels to present 'services' (Cod::Service) to the network: A service is a
# simple one or two way RPC call. (one way = asynchronous) 
#
# Cod channels are serializable whereever possible. If you want to tell
# somebody where to write his answers and/or questions to, send him the
# channel! This is really powerful and used extensively in constructing the
# higher order primitives. 
#
# All Cod channels have a serializer. If you don't specify your own
# serializer, they will use Marshal.dump and Marshal.load. (see
# {Cod::SimpleSerializer}) This allows to send Ruby objects and not just
# strings by default. If you want to, you can of course go back to very strict
# wire formats, see {Cod::ProtocolBuffersSerializer} for an example of that.
#
# The goal of Cod is that you have to know only very few things about the
# network (the various transports) to be able to construct complex things. It
# handles reconnection and reliability for you. It also translates cryptic OS
# errors into plain text messages where it can't just handle them. This should
# give you a clear place to look at if things go wrong. Note that this can
# only be ever as good as the sum of situations Cod has been tested in.
# Contribute your observations and we'll come up with a way of dealing with
# most of the tricky stuff!
#
# @see Cod::Channel
#
module Cod
  # Creates a pipe connection that is visible to this process and its
  # children. 
  #
  # @see Cod::Pipe
  #
  def pipe(serializer=nil, pipe_pair=nil)
    Cod::Pipe.new(serializer)
  end
  module_function :pipe
  
  # Creates two channels based on {Cod.pipe} (unidirectional IO.pipe) and links
  # things up so that you communication is bidirectional. Writes go to 
  # #out and reads come from #in. 
  #
  # @see Cod::BidirPipe
  #
  def bidir_pipe(serializer=nil, pipe_pair=nil)
    Cod::BidirPipe.new(serializer, pipe_pair)
  end
  module_function :bidir_pipe
  
  # Creates a tcp connection to the destination and returns a channel for it.
  # 
  # @see Cod::TcpClient
  #
  def tcp(destination, serializer=nil)
    Cod::TcpClient.new(
      destination, 
      serializer || SimpleSerializer.new)
  end
  module_function :tcp
  
  # Creates a tcp listener on bind_to and returns a channel for it. 
  #
  # @see Cod::TcpServer
  #
  def tcp_server(bind_to, serializer=nil)
    Cod::TcpServer.new(
      bind_to, 
      serializer || SimpleSerializer.new)
  end
  module_function :tcp_server

  # Creates a channel based on the beanstalkd messaging queue. 
  #
  # @see Cod::Beanstalk::Channel
  # 
  def beanstalk(tube_name, server=nil)
    Cod::Beanstalk::Channel.new(tube_name, server||'localhost:11300')
  end
  module_function :beanstalk

  # Runs a command via Process.spawn, then links a channel to the commands
  # stdout and stdin. Returns the commands pid and the channel. 
  #
  # Example: 
  #   pid, channel = Cod.process('cat')
  #
  # @see Cod::Process
  #
  def process(command, serializer=nil)
    Cod::Process.new(command, serializer)
  end
  module_function :process
  
  # Links a process' stdin and stdout up with a pipe. This means that the
  # pipes #put method will print to stdout, and the #get method will read from 
  # stdin.
  #
  # @see Cod::Pipe
  #
  def stdio(serializer=nil)
    Cod::Pipe.new(serializer, [$stdin, $stdout])
  end
  module_function :stdio
  
  # Indicates that the given channel is write only. This gets raised on 
  # operations like #put.
  #
  class WriteOnlyChannel < StandardError
    def initialize
      super("This channel is write only, attempted read operation.")
    end
  end
  
  # Indicates that the channel is read only. This gets raised on operations
  # like #get. 
  #
  class ReadOnlyChannel < StandardError
    def initialize
      super("This channel is read only, attempted write operation.")
    end
  end
  
  # Indicates that a standing connection was lost and must be reconnected. 
  # 
  class ConnectionLost < StandardError
    def initialize
      super "Connection lost."
    end
  end
end

require 'cod/select_group'
require 'cod/select'

require 'cod/iopair'

require 'cod/channel'

require 'cod/simple_serializer'

require 'cod/pipe'
require 'cod/bidir_pipe'

require 'cod/process'

require 'cod/tcp_client'
require 'cod/tcp_server'

require 'cod/service'
require 'cod/beanstalk'

