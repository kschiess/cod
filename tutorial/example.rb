require 'tempfile'

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
    
    tempfiles = {
      err: Tempfile.new('exerr'),
      out: Tempfile.new('exout')
    }
    # Close the files, but don't unlink
    tempfiles.each { |_,io| io.close(false) }
    
    Process.wait fork { 
      redirect_streams(tempfiles)
      eval(example_code) }
      
    tempfiles.each do |name, io|
      puts "Tempfile #{name} contains:"
      print File.read(io.path)
    end
    
    return true
  end
  
  def redirect_streams(io_hash)
    {
      out: $stdout, 
      err: $stderr
    }.each do |name, io|
      io.reopen(io_hash[name])
    end
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