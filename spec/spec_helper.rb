
require 'cod'
require 'timeout'

RSpec.configure do |config|
  config.mock_with :flexmock
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