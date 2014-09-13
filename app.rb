require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'rack-timeout'
require 'slim'

require_relative 'lib/number_signer'
require_relative 'apps/phone'
require_relative 'models/recording'

Rack::Timeout.timeout = 10

class Loop < Sinatra::Base
  use Rack::Timeout
  Rack::Timeout.timeout = 10

  configure :production do

    # use sentry/raven
    require 'raven'
    Raven.configure {|c| c.dsn = ENV['SENTRY_DSN'] }
    use Raven::Rack

    # less verbose sql logging
    ActiveRecord::Base.logger.level = Logger::WARN if ActiveRecord::Base.logger
  end

  use Phone
end
