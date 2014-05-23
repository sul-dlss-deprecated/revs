class NewIndexAndRequestFlagEmail < ActiveRecord::Migration
  def change
    add_index :galleries, :position
    add_column :flags,:notification_state,:string
  end
end
