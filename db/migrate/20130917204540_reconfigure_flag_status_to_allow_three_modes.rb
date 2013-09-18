class ReconfigureFlagStatusToAllowThreeModes < ActiveRecord::Migration
  def change
  change_table :flags do |f|
    f.remove :resolved
    f.string :flag_state
  end
end
  
end
