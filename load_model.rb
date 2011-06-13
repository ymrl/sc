load 'models.rb'
def load_model
  load 'models.rb'
end

def reset_tables
  Messages.drop_table if Messages.table_exists?
  Users.drop_table if Users.table_exists?
  Favs.drop_table if Favs.table_exists?
  Messages.create_table
  Users.create_table
  Favs.create_table
end
