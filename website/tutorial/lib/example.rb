require 'tempfile'
require 'cod'

class Example
  def initialize(title, file, line)
    @title = title
    @file, @line = file, line
    @lines = []
    @sites = {}
    @site_by_line = {}
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
    
    # Where code results are communicated.  
    $instrumentation = Cod.pipe
    
    code = produce_example_code
    Process.wait fork { 
      redirect_streams(tempfiles)
      # puts example_code
      eval(code, nil, @file, @line) 
    }

    # Read these tempfiles.
    @output = tempfiles.inject({}) { |h, (name, io)| 
      io.rewind
      h[name] = io.read; 
      io.close 
      h }
      
    loop do
      site_id, probe_value = $instrumentation.get rescue break
      fail "No such site #{site_id}." unless @sites.has_key?(site_id)

      @sites[site_id].store probe_value
    end

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
  
  def produce_example_code
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
      
      site = Site.new(line, md[:pre], md[:expectation].strip) 
      add_site site
      
      site.to_instrumented_line }
  end
  def add_site(site)
    @sites[site.id] = site
    @site_by_line[site.original_line] = site
  end
  def produce_modified_code
    @lines.map { |line| 
      site = @site_by_line[line]
      next line unless site 
      
      site.format_documentation_line }
  end
  def check_expectations
    @sites.each do |_, site|
      site.check
    end
  end
  
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
      "#@code # => #{value_str}"
    end
    def format_values
      v = @values.size == 1 ? @values.first : @values
      s = v.inspect
      
      s.size > 47 ? s[0,47] + '...' : s
    end
    def check
      return true if !@expectation || @expectation.match(/^\s*$/)
      if format_values != @expectation
        fail "Expectation violated, should have gotten: \n"+
          "  #{@expectation}, but was \n"+
          "  #{format_values}."
      end
    end
    def store(value)
      @values << value
    end
  end
end