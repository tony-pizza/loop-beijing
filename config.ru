if ENV['RACK_ENV'] != 'production'
  require 'dotenv'
  Dotenv.load
end

require './app.rb'
run Loop
