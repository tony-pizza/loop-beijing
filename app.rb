require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'slim'

class Recording < ActiveRecord::Base
  def self.nearest(line, id = nil)
    return where(bus: line).first if id.nil?
    where(id: id, bus: line).first || where(bus: line).first
  end

  def self.next(line, id)
    where(id: id, bus: line).offset(1).first
  end

  def self.prev(line, id)
    where(id: id, bus: line).offset(-1).first
  end

  def self.exists_for_bus?(line)
    where(bus: line).exists?
  end
end

class Phone < Sinatra::Application

  set :slim, pretty: true

  paths main:   '/phone/main',
        line:   '/phone/bus/:line',
        first:  '/phone/bus/:line/recordings/first',
        play:   '/phone/bus/:line/recordings/:id',
        next:   '/phone/bus/:line/recordings/:id/next',
        prev:   '/phone/bus/:line/recordings/:id/previous',
        create: '/phone/bus/:line/recordings',
        new:    '/phone/bus/:line/recordings/new'

  before do
    content_type :xml
    logger.info "Params: #{params}"
  end

  # main menu
  get :main do
    slim :menu
  end

  # interpret main menu input
  post :main do
    redirect path_to(:line).with(params[:Digits])
  end

  get :line do
    slim :bus, locals: { has_recordings: Recording.exists_for_bus?(params[:line]) }
  end

  get :play do
    slim :play, locals: { recording: Recording.nearest(params[:id], params[:line]) }
  end

  get :first do
    redirect path_to(:play).with(params[:line], Recording.where(bus: params[:line]).first.id)
  end

  get :next do
    redirect path_to(:play).with(params[:line], Recording.next(params[:line], params[:id]))
  end

  get :prev do
    redirect path_to(:play).with(params[:line], Recording.prev(params[:line], params[:id]))
  end

  post :line do
    if params[:Digits] == '*'
      redirect path_to(:new).with(params[:line])
    elsif Recording.exists_for_bus?(params[:line])
      redirect path_to(:first).with(params[:line])
    else
      redirect path_to(:line).with(params[:line])
    end
  end

  post :play do
    redirect case params[:Digits]
      when '1'
        redirect path_to(:prev).with(params[:line], params[:id])
      when '2'
        redirect path_to(:next).with(params[:line], params[:id])
      when '*'
        redirect path_to(:new).with(params[:line])
      end
  end

  get :new do
    slim :new
  end

  post :create do
    redirect path_to(:menu)
  end
end

class Loop < Sinatra::Base
  use Phone
end
