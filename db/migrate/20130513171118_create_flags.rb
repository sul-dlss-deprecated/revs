class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.integer :user_id
      t.string :druid, :null=>false
      t.string :flag_type, :null=>false, :default=>'error'
      t.text :comment
      t.datetime :cleared
      t.timestamps :null=>false
    end
    add_index :flags,:druid
    add_index :flags, :flag_type
    add_index :flags, :user_id
  end
end
