class Web < Sinatra::Application

  set :app_file, settings.root + '/../app.rb'
  set :views, settings.root + '/views'
  set :public_dir, settings.root + '/public'
  # set :slim, pretty: true

  # paths index:   '/'

  # get :index do
  # end

  get '/' do
    'hi'
  end

end
