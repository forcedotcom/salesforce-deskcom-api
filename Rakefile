require 'rubygems'
begin
  require 'bundler/setup'
  Bundler::GemHelper.install_tasks
rescue
  puts 'although not required, bundler is recommened for running the tests'
end

require 'appraisal'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["--color", '--format doc']
end

desc 'starts a console with the spec helpers preloaded'
task :console do
  require 'desk_api'
  # require config if we have it
  require './config' rescue nil

  DeskApi.configure do |config|
    DeskApi::CONFIG.each do |key, value|
      config.send "#{key}=", value
    end
  end if DeskApi::CONFIG
  
  begin
    require 'pry'
    Pry.start binding, quiet: true
  rescue LoadError
    puts "Looks like pry is not installed or loaded."
  end
end

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task default: :appraisal
else
  task default: :spec
end
