
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'cod'

Cod.setup(:default, :method => :pipe)

mbox = Cod::Mailbox.anonymous

mbox.write('foo')
mbox.write('bar')

mbox.waiting?  # => true
p mbox.read # => 'foo'
p mbox.read # => 'bar'