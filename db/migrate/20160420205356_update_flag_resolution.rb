class UpdateFlagResolution < ActiveRecord::Migration
  def change
    change_column :flags, :resolution, :text
  end
end
