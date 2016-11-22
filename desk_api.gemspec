# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'desk_api/version'

Gem::Specification.new do |gem|
  gem.name              = 'desk_api'
  gem.summary           = 'A lightweight, flexible client for the desk.com APIv2.'

  gem.description       = <<-EOF
    This is a lightweight, flexible ruby gem to interact with the desk.com APIv2.
    It allows to create, read and delete resources available through the API
    endpoints. It can be used either with OAuth or HTTP Basic Authentication.
  EOF

  gem.homepage          = 'http://github.com/tstachl/desk_api'
  gem.version           = DeskApi::VERSION

  gem.authors           = ['Thomas Stachl', 'Andrew Frauen']
  gem.email             = ['tstachl@salesforce.com', 'afrauen@salesforce.com']

  gem.license           = 'BSD 3-Clause License'

  gem.require_paths     = ['lib']
  gem.files             = `git ls-files -- lib/*`.split("\n") + %w(LICENSE.txt README.md)
  gem.test_files        = `git ls-files -- spec/*`.split("\n")
  gem.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  gem.extra_rdoc_files  = ['README.md']

  gem.add_runtime_dependency('faraday', '>= 0.8', '< 1.0')
  gem.add_runtime_dependency('simple_oauth', '>= 0.1', '<= 0.3')
  gem.add_runtime_dependency('addressable', '>= 2.3', '< 2.4')

  gem.add_development_dependency('rake', '>= 10.1', '< 10.4')
  gem.add_development_dependency('rspec', '>= 2.6', '< 2.15')
  gem.add_development_dependency('vcr', '>= 2.0', '< 3')
  gem.add_development_dependency('simplecov', '>= 0.7', '< 0.9')
  gem.add_development_dependency('coveralls', '>= 0.6', '< 0.8')
  gem.add_development_dependency('appraisal', '>= 1.0.0', '< 1.1')

  gem.required_ruby_version = '>= 1.9.2'
end
