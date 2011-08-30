
require 'cod'

n, msg, *args = ARGV

connection = Cod.tcp('localhost:12345')

n.to_i.times do
  connection.put [:rpc, msg.to_sym, args]
end
