class LoginCount < ActiveRecord::Migration
  def change
    add_column :users, :login_count, :integer, :null=>false, :default=>0
  end
end
