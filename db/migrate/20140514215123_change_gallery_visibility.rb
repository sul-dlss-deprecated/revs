class ChangeGalleryVisibility < ActiveRecord::Migration
  def change
  	 add_column :galleries, :visibility, :string
  	 Gallery.where(:public=>true).each {|gallery| gallery.update_column(:visibility,'public') }
  	 Gallery.where(:public=>false).each {|gallery| gallery.update_column(:visibility,'private') }
  	 remove_column :galleries, :public
  end
end
