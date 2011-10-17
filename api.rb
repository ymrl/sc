def recent t=Time.now-60
  { :since=>t.to_i,:time=>Time.now.to_i,
    :messages=>Sequel.models_to_hash(Messages.recent(t)),
    :users=>Sequel.models_to_hash(Users.current_member),
    :favs=>Sequel.models_to_hash(Favs.recent(t)),
  }
end

get '/api/chat/recent.json' do
  user = (session[:user_id] ? Users.filter(:id=>session[:user_id]).first : nil)
  user.update_time if user
  t = params[:since]? Time.at(params[:since].to_i) : Time.now - 60
  recent(t).to_json
end

post '/api/messages/new.json' do
  user = (session[:user_id] ? Users.filter(:id=>session[:user_id]).first : nil)
  user.update_time if user
  ret = {:logged_in=>(user ? true : false)}
  t = params[:since]? Time.at(params[:since].to_i) : Time.now - 60
  if !user then
    ret[:complete] = false
    ret[:warn] = "Broken Session"
  elsif params[:message].to_s.length == 0 or params[:message].to_s.length > 1000 then
    ret[:complete] = false
    ret[:warn] = "The message need to be 'message.length > 0 && message.length < 1000'." 
  else
    m = Messages.post_message(user,params[:message])
    ret[:complete] = true
    ret[:message_id] = m.id
  end
  ret[:recent] = recent(t)
  content_type :json
  ret.to_json
end


post '/api/messages/:num/add_fav.json' do |num|
  user = (session[:user_id] ? Users.filter(:id=>session[:user_id]).first : nil)
  user.update_time if user
  ret = {:logged_in=>(user ? true : false)}
  message_id = num.to_i
  message = Messages.filter(:id=>message_id.to_i).first
  if message and user
    Favs.fav message,user
    ret[:complete=>true]
  else
    ret[:complete=>false]
  end
  ret[:recent] = recent
  ret.to_json
end


post '/api/user/login.json' do
  ret = {}
  check = true
  user = (session[:user_id] ? Users.filter(:id=>session[:user_id]).filter(:joined=>true).first : nil)

  if user and user.alive?
    ret[:complete] = false
    ret[:warn] = "You are already logged in as #{user.name}. Please reload this page."
  elsif !params[:name] or !Users.name_check(params[:name])
    ret[:complete] = false
    ret[:warn] = "Please enter your name (name.length <= 100)"
  else
    name = params[:name].to_s
    exists = Users.filter(:name=>name).order_by(:modified).reverse.first
    if exists and exists.alive? 
      ret[:complete] = false
      ret[:warn] = "Your name has been used by the other people (session). Please input other name."
    elsif exists
      user = exists
      session[:user_id] = user.id
      user.update_time(true)
      ret[:name] = name
      ret[:complete] = true
    else
      user = Users.sign_up(name)
      session[:user_id] = user.id
      ret[:name] = name
      ret[:complete] = true
    end
  end
  content_type :json
  ret.to_json
end
