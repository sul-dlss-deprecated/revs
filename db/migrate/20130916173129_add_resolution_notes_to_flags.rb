class AddResolutionNotesToFlags < ActiveRecord::Migration
  def change
    change_table :flags do |f|
      f.string :resolution
      f.integer :resolving_user
    end
  end
end
