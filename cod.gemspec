# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'cod'
  s.version = '0.4.0'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Kaspar Schiess']
  s.date = '2011-07-20'
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(Gemfile HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,examples}/**/*")
  s.homepage = 'http://kschiess.github.com/cod'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.rubygems_version = '1.5.2'
  s.summary = %Q(Really simple IPC.)
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'sdoc'
end
