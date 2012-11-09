class AddUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.timestamps
    end
    
  end

  def down
    drop_dable :users
  end
end
