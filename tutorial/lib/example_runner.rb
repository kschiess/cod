
require 'case'
require 'text/highlight'

require 'example'

class ExampleRunner
  def initialize
    @state = :outside
    @line_count = 0
  end
  
  def consume(line, file)
    @line_count += 1
    
    a = lambda { |*args| Case::Array[*args] }
    any = Case::Any
    
    case [@state, line]
      when a[:outside, /<pre><code class="sh_ruby" title="(.*)">/]
        extract_title(line, file)
        enter :inside
      when a[:inside, %r(</code></pre>)]
        enter :outside
      when a[:inside, any]
        @example << line
    else
      # do nothing
    end
  end
  
  def extract_title(line, file)
    if md=line.match(/title="(.*)"/)
      @example = Example.new(md[1], file, @line_count)
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
        consume(line.chomp, name) }
    end
  end
  
  def run_example
    String.highlighter = Text::ANSIHighlighter.new
    print "Running #@example... "
    
    if @example.skip?
      puts "Skipped, no inspection points."
      return
    end
    
    unless @example.run
      puts "error".red
      @example.output[:err].lines.each { |line| 
        print "  " + line.magenta }
      return
    end
    
    puts 'ok.'.green
    @example = nil
  end
end

if $0 == __FILE__
  ExampleRunner.new.run(ARGV)
end