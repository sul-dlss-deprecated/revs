class RemoveFlagStateAddStateToFlags < ActiveRecord::Migration
  def change
  change_table :flags do |f|
    f.remove :flag_state
    f.string :state, :default => 'open'
  end
end
end
