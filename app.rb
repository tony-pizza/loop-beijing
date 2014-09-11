require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'slim'

require_relative 'apps/phone'
require_relative 'models/recording'

if ENV['RACK_ENV'] == 'production' && !ENV['SENTRY_DSN'].nil?
  require 'raven'
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
  end
end

class Loop < Sinatra::Base
  configure :production do
    use Raven::Rack
    ActiveRecord::Base.logger.level = Logger::WARN
  end

  use Phone
end
