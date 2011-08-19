$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'cod'


raise unless ARGV.first

client = Cod.tcp('localhost:12345')
client.put [client, ARGV.first]

puts "Waiting..."
$stdin.gets

