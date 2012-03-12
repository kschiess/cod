$:.unshift File.expand_path(File.dirname(__FILE__) + "/../../lib")
$:.unshift File.expand_path(File.dirname(__FILE__)) + "/../"
require 'cod'
require 'example_scaffold'
require 'pp'
require 'timeout'

def timeout_no_exception(seconds)
  timeout(seconds, &Proc.new)
  false
rescue Timeout::Error
  true
end

client {
  answer_map = Hash.new(0)

  1000.times do
    chan = Cod.tcp('localhost:32423')
    chan.put :hei

    pid = chan.get
    answer_map[pid] += 1

    chan.close
  end
  
  pp answer_map
}

server {
  server = Cod.tcp_server('localhost:32423')
  8.times do 
    fork {
      loop do
        break if timeout_no_exception(1) do
          m, chan = server.get_ext
          chan.put Process.pid
          chan.close
        end
      end
    }
  end
}

run
