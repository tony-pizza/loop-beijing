require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'rack-timeout'
require 'newrelic_rpm'
require 'slim'

require_relative 'lib/number_signer'
require_relative 'apps/phone'
require_relative 'apps/web/v1'
require_relative 'apps/web/jue'
require_relative 'models/recording'

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

  use Web::V1
  use Web::Jue
  use Phone
end
