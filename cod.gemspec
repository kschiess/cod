# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'cod'
  s.version = '0.4.2'

  s.authors = ['Kaspar Schiess']
  s.email = 'kaspar.schiess@absurd.li'

  s.extra_rdoc_files = ['README']
  s.files = %w(Gemfile HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,examples}/**/*")
  s.homepage = 'http://kschiess.github.com/cod'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.summary = %Q(Really simple IPC.)
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'yard'

  s.add_development_dependency 'guard'
  s.add_development_dependency 'growl'
end
