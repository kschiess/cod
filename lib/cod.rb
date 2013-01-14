require 'stringio'

# The core concept of Cod are 'channels'. (see {Cod::Channel::Base}) You can
# create such channels on top of the various transport layers. Once you have
# such a channel, you #put messages into it and you #get messages out of it.
# Messages are retrieved in FIFO manner.
# 
#   channel.put :test1
#   channel.put :test2
#   channel.get # => :test1
#
# Cod also brings a few abstractions layered on top of channels: You can use
# channels to present 'services' (Cod::Service) to the network: A service is a
# simple one or two way RPC call. (one way = asynchronous) 
#
#   client = channel.client
#   client.notify [:foo, :bar]
#
# Cod channels are serializable whereever possible. If you want to tell
# somebody where to write his answers and/or questions to, send him the
# channel! This is really powerful and used extensively in constructing the
# higher order primitives. 
#
#   server.put [:some_request, my_channel]
#   # Server will receive my_channel and be able to contact us there.
#
# All Cod channels have a serializer. If you don't specify your own
# serializer, they will use Marshal.dump and Marshal.load. (see
# {Cod::SimpleSerializer}) This allows to send Ruby objects and not just
# strings by default. If you want to, you can of course go back to very strict
# wire formats, see {Cod::ProtocolBuffersSerializer} or {Cod::LineSerializer}
# for an example of that.
#
#   line_protocol_channel = Cod.pipe(Cod::LineSerializer.new)
#   line_protocol_channel.put 'some_string'
#
# The goal of Cod is that you have to know only very few things about the
# network (the various transports) to be able to construct complex things. It
# also translates cryptic OS errors into plain text messages where it can't
# just handle them. This should give you a clear place to look at if things go
# wrong. Note that this can only be ever as good as the sum of situations Cod
# has been tested in. Contribute your observations and we'll come up with a
# way of dealing with most of the tricky stuff!
#
# @see Cod::Channel
# 
# == Types of channels in this version
# 
# {Cod.pipe} :: Transports via +IO.pipe+
# {Cod.tcp}  :: Transports via TCP (client)
# {Cod.tcp_server} :: Transports via TCP (as a server)
# {Cod.stdio} :: Connects to +$stdin+ and +$stdout+ (+IO.pipe+)
# {Cod.process} :: Spawn a child process and connects to that process' +$stdin+ and +$stdout+ (+IO.pipe+)
# {Cod.beanstalk} :: Transports via a tube on beanstalkd
#
module Cod
  # Creates a pipe connection that is visible to this process and its
  # children. 
  #
  # @param serializer [#en,#de] optional serializer to use
  # @return [Cod::Pipe]
  #
  def pipe(serializer=nil)
    Cod::Pipe.new(serializer)
  end
  module_function :pipe
  
  # Creates a channel based on socketpair (UNIXSocket.pair). This is a
  # IPC-kind of channel that can be used to exchange messages both ways. 
  #
  # @overload bidir_pipe(serializer=nil)
  #   @param serializer [#en,#de] optional serializer to use
  #   @return [Cod::BidirPipe]
  #
  def bidir_pipe(serializer=nil)
    Cod::BidirPipe.new(serializer)
  end
  module_function :bidir_pipe
  
  # Creates a tcp connection to the destination and returns a channel for it.
  # 
  # @param destination [String] an address to connect to, like 'localhost:1234'
  # @param serializer [#en,#de] optional serializer to use
  # @return [Cod::TcpClient]
  #
  def tcp(destination, serializer=nil)
    Cod::TcpClient.new(
      destination, 
      serializer || SimpleSerializer.new)
  end
  module_function :tcp
  
  # Creates a tcp listener on bind_to and returns a channel for it. 
  #
  # @param bind_to [String] an address and port to bind to, in the form "host:port"
  # @param serializer [#en,#de] optional serializer to use
  # @return [Cod::TcpServer]
  #
  def tcp_server(bind_to, serializer=nil)
    Cod::TcpServer.new(
      bind_to, 
      serializer || SimpleSerializer.new)
  end
  module_function :tcp_server

  # Creates a channel based on the beanstalkd messaging queue. 
  #
  # @overload beanstalk(tube_name, server='localhost:11300')
  #   @param tube_name [String] name of the tube to send messages to / 
  #     receive messages from
  #   @param server [String] address of the server to connect to
  #   @return [Cod::Beanstalk::Channel]
  # 
  def beanstalk(tube_name, server=nil)
    Cod::Beanstalk::Channel.new(tube_name, server||'localhost:11300')
  end
  module_function :beanstalk

  # Runs a command via Process.spawn, then links a channel to the commands
  # stdout and stdin. 
  #
  # @param command [String] command to execute in a subprocess 
  #   (using +Process.spawn+)
  # @param serializer [#en,#de] serializer to use for all messages in channel
  # @return [Cod::Process]
  #
  def process(command, serializer=nil)
    Cod::Process.new(command, serializer)
  end
  module_function :process
  
  # Links a process' stdin and stdout up with a pipe. This means that the
  # pipes #put method will print to stdout, and the #get method will read from 
  # stdin.
  #
  # @param serializer [#en,#de] optional serializer to use
  # @return [Cod::Pipe]
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
    def initialize(msg=nil)
      super msg || "Connection lost."
    end
  end
end

require 'cod/select_group'
require 'cod/select'

require 'cod/iopair'

require 'cod/channel'

require 'cod/simple_serializer'
require 'cod/line_serializer'

require 'cod/pipe'
require 'cod/bidir_pipe'

require 'cod/process'

require 'cod/tcp_client'
require 'cod/tcp_server'

require 'cod/service'
require 'cod/beanstalk'

