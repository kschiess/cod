$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
require 'cod'
require 'cod/protocol_buffers_serializer'

require 'protocol_buffers'
require 'protocol_buffers/compiler'


ProtocolBuffers::Compiler.compile_and_load_string <<-EOS
message Foo {
  required string bar = 1;
};
EOS

pipe = Cod.pipe(Cod::ProtocolBuffersSerializer.new)

child_pid = fork do
  pipe.put Foo.new(:bar => 'bar')
  pipe.put Foo.new(:bar => 'baz')
end

begin
  p pipe.get
  p pipe.get
ensure
  Process.wait(child_pid)
end
