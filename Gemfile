source 'https://rubygems.org'

ruby '2.1.1'

gem 'sinatra'
gem 'pg'
gem 'activerecord'
gem 'sinatra-activerecord'
gem 'pry'
gem 'rake'
gem 'slim'
gem 'sinatra-snap', git: 'https://github.com/bcarlso/snap.git'

group :production do
  gem "sentry-raven", git: 'https://github.com/getsentry/raven-ruby.git'
end

group :development do
  gem 'thin'
  gem 'shotgun'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'database_cleaner'
end
