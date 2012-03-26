require 'case'

class ExampleRunner
  def initialize
    @state = :outside
  end
  
  def consume(line)
    a = lambda { |*args| Case::Array[*args] }
    any = Case::Any
    
    case [@state, line]
      when a[:outside, /<pre><code class="sh_ruby">/]
        enter :inside
      when a[:inside, %r(</code></pre>)]
        puts
        enter :outside
      when a[:inside, any]
        puts "Example line: #{line}"
    else
      # do nothing
    end
  end
  
  def enter(new_state)
    @state = new_state
  end
  
  def run(args)
    Dir['*.textile'].each do |name|
      File.readlines(name).each { |line|
        consume(line) }
    end
  end
end

if $0 == __FILE__
  ExampleRunner.new.run(ARGV)
end