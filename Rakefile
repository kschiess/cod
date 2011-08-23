require "rubygems"
require "rdoc/task"
require 'rspec/core/rake_task'
require 'rubygems/package_task'

desc "Run all tests: Exhaustive."
RSpec::Core::RakeTask.new

task :default => :spec

require 'sdoc'

# Generate documentation
RDoc::Task.new do |rdoc|
  rdoc.title    = "parslet - construction of parsers made easy"
  rdoc.options << '--line-numbers'
  rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
  rdoc.template = 'direct' # lighter template used on railsapi.com
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "lib/**/*.rb")
  rdoc.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc'
task :clean => [:clobber_rdoc, :clobber_package]

# This task actually builds the gem. 
task :gem => :spec
spec = eval(File.read('cod.gemspec'))

desc "Generate the gem package."
Gem::PackageTask.new(spec) do |pkg|
  # pkg.need_tar = true
end
