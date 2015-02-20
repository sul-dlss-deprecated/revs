class AddTitleToItem < ActiveRecord::Migration
  def change
    add_column :items,:title,:string, :limit=>400
  end
end
