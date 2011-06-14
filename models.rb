require 'sequel'
Sequel::Model.plugin(:schema)
Sequel.connect("sqlite://db/sc.db")
EXPIRE_TIME = 60*10

module Sequel
  class Model
    def to_hash
      r = {}
      self.columns.each{|c|r[c] = self[c] if self[c] != nil}
      return r
    end
  end
  def Sequel.models_to_hash a
    a.map{|e| e.to_hash }
  end
end

class Messages < Sequel::Model
  set_schema do
    primary_key :id
    integer :user_id
    string :name
    string :content
    integer :favs
    timestamp :modified
    timestamp :created
  end

  def Messages.post_message user,message
    return Messages.create({
      :user_id => user.id,
      :name => user.name,
      :content => message,
      :favs => 0,
      :modified =>Time.now,
      :created =>Time.now
    })
  end
  def Messages.recent t=Time.now-60
    t = Time.now - 7200 if Time.now - t > 7200
    Messages.filter{created>=t}.order_by(:id).select(:id,:name,:content,:favs,:created).all
  end
end

class Favs < Sequel::Model
  set_schema do
    primary_key :id
    integer :user_id
    integer :message_id
    integer :total
    timestamp :modified
    timestamp :created
  end
  def Favs.fav message,user
    favs = message.favs
    message.update(:favs => favs+1,:modified=>Time.now)
    Favs.create(:message_id=>message.id,:user_id=>user.id,:total=>favs+1,:created=>Time.now,:modified=>Time.now)
  end
  def Favs.recent t=Time.now-60
    t = Time.now - 7200 if Time.now - t > 7200
    Favs.filter{modified>=t}.order_by(:id).select(:id,:total,:message_id).all
  end
end

class Users < Sequel::Model
  set_schema do
    primary_key :id
    string :name
    bool :joined
    timestamp :modified
    timestamp :created
  end

  def update_time f=false
    if f or Time.now - self.modified > EXPIRE_TIME * 0.8
      self.update(:modified => Time.now)
    end
    return self
  end
  def Users.sign_up name
    Users.create(:name=>name,:joined=>true,:created=>Time.now,:modified=>Time.now)
  end
  def expired?
    return !(self.modified and Time.now - self.modified < EXPIRE_TIME)
  end
  def alive?
    return (self.joined and !expired?)
  end
  def Users.current_member 
    Users.filter{(modified > Time.now-EXPIRE_TIME)}.filter(:joined=>true).select(:id,:name).all
  end
  def Users.name_check str
    return (str.to_s.length > 0 and str.to_s.length <= 30) 
  end
end

Messages.create_table if !Messages.table_exists?
Users.create_table if !Users.table_exists?
Favs.create_table if !Favs.table_exists?
