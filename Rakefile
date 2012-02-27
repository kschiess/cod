require "rubygems"
require "rdoc/task"
require 'rspec/core/rake_task'
require 'rubygems/package_task'

desc "Run all tests: Exhaustive."
RSpec::Core::RakeTask.new

task :default => :spec

task :stats do
  %w(lib spec).each do |path|
    printf "%10s:", path
    system %Q(find #{path} -name "*.rb" | xargs wc -l | grep total)
  end
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  # t.files   = ['lib/**/*.rb']
  # t.options = ['--any', '--extra', '--opts'] # optional
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
