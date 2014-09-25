class Web < Sinatra::Application

  set :app_file, settings.root + '/../app.rb'
  set :views, settings.root + '/views/web'
  set :public_dir, settings.root + '/public'
  set :slim, pretty: settings.development?

  get /w*(\.html?)?/ do
    <<-EOHTML
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Interactive and participatory audio installations on Beijing public buses." />
  <meta name="keywords" content="loop, beijing, loop beijing, buses, beijing design week, audio installation" />
	<title>LOOP Beijing</title>
  <style type="text/css">
    body {
      background: url(/images/bg.jpg) no-repeat fixed;
      background-size: cover;
      color: #FFFFFF;
      font-family: Helvetica, Arial, "Microsoft Yahei", "微软雅黑", 黑体, SimHei, "华文黑体", STHeiti, STXihei, "华文细黑", sans-serif;
      font-size: 100%;
      line-height: 1.5em;
      text-align: center;
    }
  </style>
</head>
<body>
<div style="top: 20%; position: absolute; width: 100%;">
  <img src="/images/logo.png" />
</div>
</body>
</html>
    EOHTML
  end

  not_found do
    redirect '/'
  end

  error do
    redirect '/'
  end

  get '/new' do
    redirect '/' unless settings.development?
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
    redirect '/' unless settings.development?

    transloadit_results = JSON.parse(params['transloadit'])['results']
    original = transloadit_results[':original'].first
    mp3 = transloadit_results['mp3'].first

    Recording.create!(
      bus: params[:recording][:bus],
      original_url: original['url'],
      web_url: mp3['url'],
      duration: original['meta']['duration']
    )

    redirect '/'
  end

end
