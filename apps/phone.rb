class Phone < Sinatra::Application

  set :app_file, settings.root + '/../app.rb'
  set :views, settings.root + '/views/phone'
  set :slim, pretty: true

  paths main:    '/phone/main',
        line:    '/phone/bus/:line',
        confirm: '/phone/bus/:line/confirm',
        first:   '/phone/bus/:line/play',
        new:     '/phone/bus/:line/record',
        play:    '/phone/bus/:line/recordings/:id',
        next:    '/phone/bus/:line/recordings/:id/next',
        prev:    '/phone/bus/:line/recordings/:id/previous',
        end:     '/phone/bus/:line/end',
        create:  '/phone/bus/:line/recordings'

  RECORD_BUTTON = '9'
  HOME_BUTTON = '0'
  NEXT_BUTTON = '3'
  PREV_BUTTON = '1'

  before do
    content_type :xml
  end

  after do
    logger.info "Params: #{params}"
  end

  # main menu
  get :main do
    slim :menu
  end

  # interpret main menu input
  post :main do
    redirect path_to(:confirm).with(params[:Digits])
  end

  get :confirm do
    slim :confirm
  end

  post :confirm do
    if params[:Digits] == HOME_BUTTON
      redirect path_to(:main)
    else
      redirect path_to(:line).with(params[:line])
    end
  end

  get :line do
    slim :bus, locals: { has_recordings: Recording.exists_for_bus?(params[:line]) }
  end

  get :play do
    slim :play, locals: { recording: Recording.nearest(params[:line], params[:id]) }
  end

  get :first do
    redirect path_to(:play).with(params[:line], Recording.where(bus: params[:line]).last.id)
  end

  get :next do
    if next_recording = Recording.next(params[:line], params[:id])
      redirect path_to(:play).with(params[:line], next_recording.id)
    else
      redirect path_to(:end).with(params[:line])
    end
  end

  get :prev do
    if prev_recording = Recording.prev(params[:line], params[:id])
      redirect path_to(:play).with(params[:line], prev_recording.id)
    else
      redirect path_to(:play).with(params[:line], params[:id])
    end
  end

  get :end do
    slim :end
  end

  post :line do
    redirect case params[:Digits]
      when HOME_BUTTON
        path_to(:main)
      when RECORD_BUTTON
        path_to(:new).with(params[:line])
      else
        if Recording.exists_for_bus?(params[:line])
          path_to(:first).with(params[:line])
        else
          path_to(:line).with(params[:line])
        end
      end
  end

  post :play do
    redirect case params[:Digits]
      when HOME_BUTTON
        path_to(:main)
      when PREV_BUTTON
        path_to(:prev).with(params[:line], params[:id])
      when NEXT_BUTTON
        path_to(:next).with(params[:line], params[:id])
      when RECORD_BUTTON
        path_to(:new).with(params[:line])
      else
        path_to(:play).with(params[:line], params[:id])
      end
  end

  get :new do
    slim :new
  end

  post :create do
    Recording.create!(bus: params[:line], url: params[:RecordingUrl])
    redirect path_to(:line).with(params[:line])
  end
end
