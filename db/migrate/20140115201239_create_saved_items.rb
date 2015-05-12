class CreateSavedItems < ActiveRecord::Migration
  def change
    create_table :saved_items do |t|
      t.string :druid, :null=>false
      t.integer :gallery_id,  :null => false
      t.text   :description
      t.timestamps :null=>false
    end
    add_index :saved_items,:druid
    add_index :saved_items,:gallery_id    
  end
end
