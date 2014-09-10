ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'database_cleaner'
require_relative '../app.rb'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Loop
  end
end

ActiveRecord::Base.logger = nil
ActiveRecord::Migration.check_pending!

RSpec.configure do |config|
  config.tty = true
  config.color = true
  config.formatter = :documentation
  config.include RSpecMixin

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
