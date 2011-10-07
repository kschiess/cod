
require 'cod'

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

# Allows definition of multiple local variables as follows: 
#   mlet(:a, :b) { [:a, :b] }
#   # a.should == :a
#   # b.should == :b
#
def mlet(*names, &block)
  compound_name = names.join('_')
  names.each_with_index do |name, idx|
    let(name) {
      @memoize ||= Hash.new
      (@memoize[compound_name] ||= block.call)[idx]
    }
  end
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