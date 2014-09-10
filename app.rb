require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'slim'

require_relative 'apps/phone'
require_relative 'models/recording'

class Loop < Sinatra::Base
  use Phone
end
