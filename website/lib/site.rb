class Site
  attr_reader :original_line
  
  def initialize(original_line, code, expectation)
    @original_line = original_line
    @code = code
    @expectation = expectation
    @values = []
  end
  def id
    object_id
  end
  def to_instrumented_line
    "(#@code).tap { |o| $instrumentation.put [#{id}, o] }"
  end
  def format_documentation_line
    value_str = format_values
    "#@code# => #{value_str}"
  end
  def format_values
    v = @values.size == 1 ? @values.first : @values
    s = v.inspect
    
    s.size > 47 ? s[0,47] + '...' : s
  end
  def check
    return true if !@expectation || @expectation.match(/^\s*$/)

    str = format_values
    if str != @expectation
      puts "      #{@code.strip} # => #{str.red}"
      puts "      #{' '*@code.size} # expected: #@expectation"
    else
      puts "      #{@code.strip} # => #{str.green}"
    end
  end
  def store(value)
    @values << value
  end
end
