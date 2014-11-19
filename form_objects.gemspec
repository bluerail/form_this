$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'form_objects'
  s.version     = '0.1'
  s.authors     = ['Martin Tournoij']
  s.email       = ['martin@lico.nl']
  s.homepage    = 'https://github.com/bluerail/form_objects'
  s.summary     = 'Form objects outside your models'
  s.description = 'Make it easy & painless to use form objects outside your models'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.markdown']
  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = '>= 2.0'

  s.add_dependency 'activerecord', '~> 4.0'
  s.add_dependency 'activemodel', '~> 4.0'
  s.add_dependency 'virtus', '~> 1.0'

  s.add_development_dependency 'rspec-rails', '~> 3.0'
end
