class AddPositionValueToExistingItems < ActiveRecord::Migration
  def change
    add_index :saved_items, :position

    galleries=Gallery.all
    galleries.each do |gallery|
        saved_items=SavedItem.where(:gallery_id=>gallery.id).where('position = 0 OR position is null').order('created_at desc') # find all gallery items with no specified position in order of date created
        n=1
        saved_items.each do |saved_item|
            saved_item.update_attribute(:position,n*10) # add increasing position values
        end
    end
  end
end
