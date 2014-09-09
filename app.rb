require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/snap'
require 'slim'

class Recording < ActiveRecord::Base
  def self.nearest(line, id = nil)
    return where(line: line).first if id.nil?
    where(id: id, line: line).first || where(line: line).first
  end

  def self.next(line, id)
    where(id: id, line: line).offset(1).first
  end

  def self.prev(line, id)
    where(id: id, line: line).offset(-1).first
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
  end

  # main menu
  get :main do
    slim :menu
  end

  # interpret main menu input
  post :main do
    redirect case params[:digits]
      when 1
       '/phone/bus/1.xml'
      when 2
       '/phone/bus/1.xml'
      when 3
       '/phone/record.xml'
      end
  end

  get :line do
    slim :bus, locals: { line: params[:line] }
  end

  get :play do
    slim :play, locals: {
      recording: Recording.where(id: params[:id], line: params[:line]).first || Recording.where(line: params[:line]).first

    }
  end

  get :first do
    redirect "/play/#{Recording.find(params[:id]).next.id}.xml"
  end

  get :next do
    redirect "/play/#{Recording.find(params[:id]).next.id}.xml"
  end

  get :prev do
  end

  post :play do
    redirect case params[:digits]
      when 1
        redirect path_to(:prev).with(params[:id])
      when 2
        redirect path_to(:next).with(params[:id])
      when 3
        redirect path_to(:main)
      end
  end

  get :new do
    slim :record
  end

  post :create do
    puts params.inspect
    redirect path_to(:menu)
  end
end

class Loop < Sinatra::Base
  use Phone
end
