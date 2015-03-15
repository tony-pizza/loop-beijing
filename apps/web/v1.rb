module Web; end
class Web::V1 < Sinatra::Application

  set :app_file, settings.root + '/../../app.rb'
  set :views, settings.root + '/views/web/v1'
  set :public_dir, settings.root + '/public'
  set :slim, pretty: settings.development?
  set :static_cache_control, [:public, max_age: 300]

  paths root:           '/2014',
        buses:          '/2014/buses',
        bus:            '/2014/buses/:line',
        recordings:     '/2014/recordings',
        new_recording:  '/2014/recordings/new'

  FEATURES = YAML.load(File.read(settings.root + '/config/featured.yml'))

  helpers do
    def nav
      %{
        <ul class="nav">
          <li>
            <a href="/">Home</a>
          </li>
          <li>
            <a href="#{path_to(:buses)}">Buses</a>
          </li>
          <li>
            <a href="#{path_to(:new_recording)}">Upload</a>
          </li>
        </ul>
      }
    end
  end

  get /^\/2014\/?(index(\.html?))?$/ do
    @body_id = 'landing'
    @buses = Recording.reorder(nil).uniq.pluck(:bus)
    slim :index
  end

  get :buses do
    @title = 'Buses'
    @buses_with_recordings = Recording.reorder(nil).uniq.pluck(:bus)
    slim :buses
  end

  get :bus do
    if params[:line] != params[:line].to_i.to_s
      redirect path_to(:bus).with(params[:line].to_i)
    end
    @title = "Bus #{params[:line]}"
    @recordings = Recording.where(bus: params[:line])
    slim :bus
  end

  get :new_recording do
    @transloadit_params = JSON.generate(
      auth: {
        key:     ENV['TRANSLOADIT_AUTH_KEY'],
        expires: (Time.now + 10.minutes).utc.strftime('%Y/%m/%d %H:%M:%S+00:00')
      },
      template_id: ENV['TRANSLOADIT_TEMPLATE_ID']
    )

    @signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'),
      ENV['TRANSLOADIT_SECRET_KEY'],
      @transloadit_params)

    @title = 'Upload'
    slim :new
  end

  post :recordings do
    transloadit_results = JSON.parse(params['transloadit'])['results']
    original = transloadit_results[':original'].first
    mp3 = transloadit_results['mp3'].first

    recording = Recording.create!(
      bus: params[:recording][:bus],
      original_url: original['url'],
      web_url: mp3['url'],
      duration: original['meta']['duration']
    )

    redirect path_to(:bus).with(recording.bus)
  end


  not_found do
    redirect path_to(:root)
  end

  error do
    redirect path_to(:root)
  end

end
