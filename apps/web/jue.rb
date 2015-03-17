module Web; end
class Web::Jue < Sinatra::Application

  set :app_file, settings.root + '/../../app.rb'
  set :views, settings.root + '/views/web/jue'
  set :public_dir, settings.root + '/public'
  set :slim, pretty: settings.development?
  set :static_cache_control, [:public, max_age: 300]

  paths root:           '/',
        music:          '/music',
        map:            '/map'

  get /^\/(index(\.html?))?$/ do
    slim :index
  end

  get :music do
    @body_id = 'music'
    slim :music
  end

  get :map do
    slim :map
  end

  not_found do
    redirect path_to(:root)
  end

  error do
    redirect path_to(:root)
  end

end
