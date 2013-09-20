class AddStateAndResolvingUserIndicesToFlags < ActiveRecord::Migration
  def change
     add_index :flags, :state
     add_index :flags, :resolving_user
     add_index :flags, :resolved_time
  end
end
