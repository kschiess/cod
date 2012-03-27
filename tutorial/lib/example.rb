require 'tempfile'

class Example
  def initialize(title)
    @title = title
    @lines = []
    @sites = []
  end
  
  def to_s
    "'#@title'"
  end
  
  def <<(line)
    @lines << line
  end
  
  attr_reader :output
  
  def skip?
    !@lines.grep(/# =>/)
  end
  
  def run
    # Create a tempfile per output
    tempfiles = [:err, :out].inject({}) { |h, name| 
      h[name] = Tempfile.new(name.to_s); h }
    
    Process.wait fork { 
      # redirect_streams(tempfiles)
      puts example_code
      # eval(example_code) 
      }

    # Read these tempfiles.
    @output = tempfiles.inject({}) { |h, (name, io)| 
      io.rewind
      h[name] = io.read; 
      io.close 
      h }

    return $?.success?
  end
  
  def redirect_streams(io_hash)
    {
      out: $stdout, 
      err: $stderr
    }.each do |name, io|
      io.reopen(io_hash[name])
    end
  end
  
  def example_code
    root = File.expand_path(File.dirname(__FILE__))

    '' <<
      "$:.unshift #{root.inspect}\n" <<
      "load 'prelude.rb'\n" <<
      instrument(@lines).join("\n") <<
      "\nload 'postscriptum.rb'\n"
  end
  def instrument(code)
    code.map { |line| 
      md = line.match(/(?<pre>.*)# =>(?<expectation>.*)/) 
      next line unless md
      
      site = Site.new(line, md[:pre], md[:expectation]) 
      @sites << site
      site.to_instrumented_line }
  end
  
  class Site
    def initialize(original_line, code, expectation)
      @code = code
    end
    def id
      object_id
    end
    def to_instrumented_line
      "(#@code).tap { |o| $instrumentation.put [#{id}, o] }"
    end
  end
end