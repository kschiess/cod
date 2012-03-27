
require 'tempfile'
require 'case'

$:.unshift '.'
require 'example'

class ExampleRunner
  def initialize
    @state = :outside
  end
  
  def consume(line)
    a = lambda { |*args| Case::Array[*args] }
    any = Case::Any
    
    case [@state, line]
      when a[:outside, /<pre><code class="sh_ruby" title="(.*)">/]
        extract_title(line)
        enter :inside
      when a[:inside, %r(</code></pre>)]
        enter :outside
      when a[:inside, any]
        @example << line
    else
      # do nothing
    end
  end
  
  def extract_title(line)
    if md=line.match(/title="(.*)"/)
      @example = Example.new(md[1])
    end
  end
  
  def enter(new_state)
    a = lambda { |*args| Case::Array[*args] }

    case [@state, new_state]
      when a[:inside, :outside]
        run_example
    end
    
    @state = new_state
  end
  
  def run(args)
    Dir['*.textile'].each do |name|
      File.readlines(name).each { |line|
        consume(line.chomp) }
    end
  end
  
  def run_example
    print "Running #@example..."
    unless @example.run
      puts "Skipped, no inspection points."
    end
    puts 'ok.'
    @example = nil
  end
end

if $0 == __FILE__
  ExampleRunner.new.run(ARGV)
end