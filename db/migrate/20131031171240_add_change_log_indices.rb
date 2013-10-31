class AddChangeLogIndices < ActiveRecord::Migration
  def change
   add_index :change_logs, :user_id
   add_index :change_logs, :druid
   add_index :change_logs, :operation
  end
end
