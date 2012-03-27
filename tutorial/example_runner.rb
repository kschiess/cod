
require 'tempfile'
require 'case'

class ExampleRunner
  def initialize
    @state = :outside
    reset_example
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
        @current_example << line
    else
      # do nothing
    end
  end
  
  def extract_title(line)
    if md=line.match(/title="(.*)"/)
      @title = md[1]
    end
  end
  
  def enter(new_state)
    a = lambda { |*args| Case::Array[*args] }

    case [@state, new_state]
      when a[:inside, :outside]
        run_example
        reset_example
    end
    
    @state = new_state
  end
  
  def run(args)
    Dir['*.textile'].each do |name|
      File.readlines(name).each { |line|
        consume(line.chomp) }
    end
  end
  
  def reset_example
    @title = nil
    @current_example = []
  end
  def run_example
    return unless @title
    unless @current_example.grep(/# =>/)
      puts "Skipping #{@title}, doesn't contain inspection points."
    end

    print "Running '#@title'..."
    tempfile = Tempfile.new('exrun')
    root = File.expand_path(File.dirname(__FILE__))
    begin
      tempfile.puts "$:.unshift #{root.inspect}"
      tempfile.puts "load 'prelude.rb'"
      tempfile.write(@current_example.join("\n"))
      tempfile.puts "\nload 'postscriptum.rb'"
      tempfile.close(false)
      
      # puts File.read(tempfile.path)
    
      pid = Process.spawn("ruby #{tempfile.path}")
      Process.wait(pid)
      puts 'done.'
    ensure 
      tempfile.close(true)
    end
  end
end

if $0 == __FILE__
  ExampleRunner.new.run(ARGV)
end