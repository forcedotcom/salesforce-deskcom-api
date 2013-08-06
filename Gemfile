source 'https://rubygems.org'

group :development, :test do |variable|
  # Testing infrastructure
  gem 'guard'
  gem 'guard-rspec'

  if RUBY_PLATFORM =~ /darwin/
    # OS X integration
    gem 'ruby_gntp'
    gem 'rb-fsevent'
  end
end

gemspec