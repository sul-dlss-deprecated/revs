class AddSlugsToGalleries < ActiveRecord::Migration
  def change
    add_column :galleries, :slug, :string, :null=>true
    add_column :galleries, :featured, :boolean, :null=>false, :default=>false
    add_column :galleries, :position, :integer
    add_index :galleries, :slug, :unique=>true
    add_index :galleries, :featured
  end
end
