require 'site'

class FailSite < Site
  def format_documentation_line
    value_str = format_values
    "#@code# raises #{value_str}"
  end

  def check
    return true if !@expectation || @expectation.match(/^\s*$/)

    str = format_values
    if str != @expectation
      puts "      #{@code.strip} # raises #{str.red}"
      puts "      #{' '*@code.size} # expected: #@expectation"
    else
      puts "      #{@code.strip} # raises #{str.green}"
    end
  end
  def store(msg)
    store_if(:raises, msg)
  end
end