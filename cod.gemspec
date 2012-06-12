# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'cod'
  s.version = '0.5.0'

  s.authors = ['Kaspar Schiess']
  s.email = 'kaspar.schiess@absurd.li'

  s.extra_rdoc_files = ['README']
  s.files = %w(HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,examples}/**/*")
  s.homepage = 'http://kschiess.github.com/cod'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.summary = %Q(Really simple IPC. Pipes, TCP sockets, beanstalkd, ...)
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'yard'

  s.add_development_dependency 'guard'
  s.add_development_dependency 'growl'
end
