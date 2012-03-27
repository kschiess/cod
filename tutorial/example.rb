class Example
  def initialize(title)
    @title = title
    @lines = []
  end
  
  def to_s
    "'#@title'"
  end
  
  def <<(line)
    @lines << line
  end
  
  def run
    unless @lines.grep(/# =>/)
      return false
    end
    return true
  end
  
  def write_instrumented_example(io)
    root = File.expand_path(File.dirname(__FILE__))
    io.puts "$:.unshift #{root.inspect}"
    io.puts "load 'prelude.rb'"
    io.write(@current_example.join("\n"))
    io.puts "\nload 'postscriptum.rb'"
    io.close(false)
  end
  
end