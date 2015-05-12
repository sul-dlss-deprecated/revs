class CreateChangeLogs < ActiveRecord::Migration
  def change
    create_table :change_logs do |t|
      t.integer :user_id, :null=>false
      t.string  :druid, :null=>false
      t.string  :operation, :null=>false
      t.text    :note
      t.timestamps :null=>false
    end
  end
end
