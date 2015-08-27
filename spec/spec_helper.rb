
require 'ae'

require 'socket'
require 'cod'
require 'timeout'

RSpec.configure do |config|
  config.mock_with :flexmock

  # Only executes examples tagged with `beanstalk: true` if beanstalk is started on
  # localhost.
  #
  begin
    s = TCPSocket.new('127.0.0.1', 11300)
    s.connect
  rescue Errno::ECONNREFUSED
    warn "*** beanstalkd   server not found. NOT running specs for beanstalk code. "
    config.filter_run_excluding beanstalk: true
  end

end

def slet(name, &block)
  let(name, &block)
  subject { self.send(name) }
end

def slet!(name, &block)
  let!(name, &block)
  subject { self.send(name) }
end

RSpec::Matchers.define(:serialize) do
  match do |given|
    begin
      Marshal.dump(given)
    rescue
      false
    end
    true
  end
end

require 'support/transport'
require 'support/beanstalk'