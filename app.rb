#coding:UTF-8
require 'sinatra'
require 'haml'
require 'cgi'
require 'json'
require 'yaml'
require File.dirname(__FILE__)+'/models.rb'
require File.dirname(__FILE__)+'/helpers.rb'
require File.dirname(__FILE__)+'/api.rb'

configure do
  config = YAML::load open(File.dirname(__FILE__)+'/config.yaml').read
  EXPIRE_TIME = config[:session][:expire].to_i
  SECRET = config[:session][:secret].to_s
  TITLE = config[:title]
  URL_BASE = config[:urlBase]
  API_BASE = config[:apiBase]
end

use Rack::Session::Cookie,
  :key => 'sc.session',
  :expire_after => EXPIRE_TIME,
  :secret => SECRET
set :haml,:format=>:html5


get '/css/main.css' do
  sass :main_style
end

=begin
get '/logs/:date_str' do |date_str|
  matched = date_str.split(/(\d{4})(\d{2})(\d{2})/)
  @message = Messages.find(:id=>id)
end
=end

get '/' do
  user = nil
  if session[:user_id] and 
    (user = Users.filter(:id=>session[:user_id]).first) and user.alive? then
    user.update_time(true)
    @logged_in = true
    @name = user.name
  else
    @logged_in = false
    @name ="no name"
  end
  @messages = Messages.order_by(:created).reverse.limit(20).all
  @members = Users.filter{modified > Time.now-EXPIRE_TIME}.filter(:joined=>true).all
  @loaded = Time.now
  haml :chat_main
end

get '/logout' do
  if user = (session[:user_id]? Users.filter(:id=>session[:user_id]).first : nil)
    user.update(:joined => false)
  end
  session.keys.each{|k|session[k] = nil}
  redirect URL_BASE + '/'
end
