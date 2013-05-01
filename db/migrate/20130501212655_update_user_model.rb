class UpdateUserModel < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.integer :role_id
      t.text :bio,              :null => false, :default => ""
      t.string :first_name, :null => false, :default => ""
      t.string :last_name, :null => false, :default => ""
    end
  end
end
