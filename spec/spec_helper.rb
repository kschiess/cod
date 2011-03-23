
require 'cod'

RSpec.configure do |config|
  config.before(:each) { Cod.reset }
end

def slet(name, &block)
  let(name, &block)
  alias_method name, :subject
end

def slet!(name, &block)
  let!(name, &block)
  alias_method name, :subject
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