require 'timeout'

begin
  timeout(1) { loop do end }
rescue Exception => ex
  p ex
end