# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'desk/version'

Gem::Specification.new do |gem|
  gem.name              = 'desk_api'
  gem.summary           = 'A lightweight, flexible wrapper for the desk.com REST API.'
  gem.description       = 'This is a lightweight, flexible ruby gem to interact with the desk.com REST API. It allows to create, read and delete resources available through the API endpoints. It can be used either with OAuth or HTTP Basic Authentication.'
  gem.homepage          = 'http://github.com/tstachl/desk.rb'
  gem.version           = Desk::VERSION

  gem.authors           = ['Thomas Stachl']
  gem.email             = 'tom@desk.com'

  gem.require_paths     = ['lib']
  gem.files             = `git ls-files`.split("\n")
  gem.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  gem.extra_rdoc_files  = ['README.md', 'CHANGELOG.md']
  gem.rdoc_options      = ['--line-numbers', '--inline--source', '--title', 'desk.rb']

  gem.add_runtime_dependency('multi_json')
  gem.add_runtime_dependency('faraday')
  gem.add_runtime_dependency('faraday_middleware')
  gem.add_runtime_dependency('typhoeus')
  gem.add_runtime_dependency('addressable')
  gem.add_runtime_dependency('activesupport')

  gem.add_development_dependency('rspec')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('vcr')
end