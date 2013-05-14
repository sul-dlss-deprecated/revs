class AddFieldsToUser < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.boolean :public,              :null => false, :default => false
      t.string :url, :null=>true, :default => ''
    end
  end
end
