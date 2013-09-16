class AddResolutionBooleanToFlags < ActiveRecord::Migration

    def change
      change_table :flags do |f|
        f.remove :cleared
        f.boolean :resolved, :default => false
        f.datetime :resolved_time
      end
    end

  
end
