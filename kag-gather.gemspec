$:.push File.expand_path('../lib', __FILE__)
require 'kag/version'

Gem::Specification.new do |gem|
  gem.name        = 'kag-gather'
  gem.version     = KAG::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = 'KAG Gather IRC Bot'
  gem.description = ''
  gem.licenses    = %w(GPLv2)

  gem.authors     = ['Shaun McCormick']
  gem.email       = %w(splittingred@gmail.com)
  gem.homepage    = 'https://github.com/splittingred/kag-gather'

  gem.required_ruby_version     = '>= 1.9.2'
  gem.required_rubygems_version = '>= 1.3.6'

  gem.files        = Dir['readme.md', 'lib/**/*', 'config/config.sample.json']
  gem.require_path = 'lib'

  gem.add_runtime_dependency "cinch", "2.0.4"
  gem.add_runtime_dependency "json"
  gem.add_runtime_dependency "symboltable", "1.0.2"
  gem.add_runtime_dependency "kagerator", "1.0.3"
  #gem.add_runtime_dependency 'timers', '>= 1.0.0'

  #if RUBY_PLATFORM =~ /java/
  #  gem.add_runtime_dependency "jruby-openssl"
  #end

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard-rspec'
  #gem.add_development_dependency 'benchmark_suite'
end