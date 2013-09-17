class AddSpamTrackingForUser < ActiveRecord::Migration
  def change
    change_table(:users) do |u|
    u.integer :spam_flags, :null=>false, :default => 0
  end
  end
  
end
