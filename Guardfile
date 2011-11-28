# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# guard 'rspec', version: 2, cli: "--format nested --fail-fast" do
guard 'rspec', version: 2, cli: "--fail-fast" do
  watch(%r'^spec/(.*)_spec.rb')
  watch(%r'^lib/(.*)\.rb')                { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')            { "spec" }
  watch(%r'^lib/.*')                      { 'spec/acceptance' }
end
