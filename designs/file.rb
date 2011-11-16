
# How does Marshal handle file ends? 

require 'tempfile'

f = Tempfile.new('design_file')

puts "Writing to #{f.path}..."
f.write Marshal.dump('s')

puts "Reading back..."
f.seek 0
p Marshal.load(f) 
