class CreateCollectionHighlights < ActiveRecord::Migration
  def change
    create_table :collection_highlights do |t|
      t.string :druid
      t.string :image_url
      t.timestamps :null=>false
    end
  end
end
