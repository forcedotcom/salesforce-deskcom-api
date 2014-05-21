# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'desk_api/version'

Gem::Specification.new do |gem|
  gem.name              = 'desk_api'
  gem.summary           = 'A lightweight, flexible wrapper for the desk.com REST API.'
  gem.description       = 'This is a lightweight, flexible ruby gem to interact with the desk.com REST API. It allows to create, read and delete resources available through the API endpoints. It can be used either with OAuth or HTTP Basic Authentication.'
  gem.homepage          = 'http://github.com/tstachl/desk'
  gem.version           = DeskApi::VERSION

  gem.authors           = ['Thomas Stachl', 'Andrew Frauen']
  gem.email             = 'tstachl@salesforce.com'

  gem.require_paths     = ['lib']
  gem.files             = `git ls-files`.split("\n")
  gem.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  gem.extra_rdoc_files  = ['README.md']
  gem.rdoc_options      = ['--line-numbers', '--inline--source', '--title', 'desk.rb']

  gem.add_runtime_dependency('faraday', '~> 0.9.0')
  gem.add_runtime_dependency('simple_oauth', '~> 0.1')
  gem.add_runtime_dependency('addressable', '~> 2.3')

  gem.add_development_dependency('rake', '~> 10.1.1')
  gem.add_development_dependency('rspec', '~> 2.6')
  gem.add_development_dependency('vcr', '~> 2.0')
  gem.add_development_dependency('simplecov', '~> 0.7')
  gem.add_development_dependency('coveralls', '~> 0.6')
end
