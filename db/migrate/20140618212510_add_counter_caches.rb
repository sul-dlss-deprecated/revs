class AddCounterCaches < ActiveRecord::Migration
  def up
    add_column :galleries,:saved_items_count,:integer, :default=>0, :null=>false
    Gallery.all.each {|gallery| Gallery.reset_counters(gallery.id,:all_saved_items)}
  end
  def down
    remove_column :galleries,:saved_items_count
  end
end
