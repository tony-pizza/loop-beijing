require './app'
require 'sinatra/activerecord/rake'

if ENV['RACK_ENV'] != 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :specs do |task|
    task.pattern = Dir['spec/**/*_spec.rb']
  end
end
