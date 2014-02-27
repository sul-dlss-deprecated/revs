class AddViewsToGalleries < ActiveRecord::Migration
  def change
    add_column :galleries, :views, :integer, :null=>false, :default=>0
    add_column :saved_items, :sort_order, :integer, :null=>false, :default=>0
  end
end
