require 'rake'

begin
  require 'bundler/setup'
  Bundler::GemHelper.install_tasks
rescue
  puts 'although not required, bundler is recommened for running the tests'
end

desc 'starts a console with the spec helpers preloaded'
task :console do
  begin
    require 'pry'
    require_relative './spec/spec_helper'
    VCR.turn_off!
    Pry.start binding, quiet: true
  rescue LoadError
    puts "Looks like pry is not installed or loaded."
  end
end

task default: :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["--color", '--format doc']
end