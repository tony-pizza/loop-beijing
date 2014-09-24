class Web < Sinatra::Application

  set :app_file, settings.root + '/../app.rb'
  set :views, settings.root + '/views/web'
  set :public_dir, settings.root + '/public'
  set :slim, pretty: settings.development?

  # paths index:   '/'

  # get :index do
  # end

  get '/' do
    transloadit_params = JSON.generate(
      auth: {
        key:     ENV['TRANSLOADIT_AUTH_KEY'],
        expires: (Time.now + 10.minutes).utc.strftime('%Y/%m/%d %H:%M:%S+00:00')
      },
      template_id: ENV['TRANSLOADIT_TEMPLATE_ID']
    )
    digest    = OpenSSL::Digest.new('sha1')
    signature = OpenSSL::HMAC.hexdigest(digest, ENV['TRANSLOADIT_SECRET_KEY'], transloadit_params)
    slim :new, locals: { digest: digest, signature: signature, transloadit_params: transloadit_params }
  end

  post '/upload' do
    puts JSON.parse(params['transloadit'])['results'][':original'].first['url']
    puts JSON.parse(params['transloadit'])['results']['mp3'].first['url']

    transloadit_results = JSON.parse(params['transloadit'])['results']
    original = transloadit_results[':original'].first
    mp3 = transloadit_results['mp3'].first

    puts original.inspect

    Recording.create!(
      bus: params[:recording][:bus],
      original_url: original['url'],
      web_url: mp3['url'],
      duration: original['meta']['duration']
    )

    redirect '/'
  end

end
