class CreateGalleries < ActiveRecord::Migration
  def change
    create_table :galleries do |t|
      t.integer :user_id, :null=>false
      t.boolean :public,  :null => false, :default => false
      t.string :title
      t.text   :description
      t.string :gallery_type, :null => false
      t.timestamps
    end
    add_index :galleries,:user_id
    add_index :galleries,:public
    add_index :galleries,:gallery_type
  end
end
