class RemoveCollectionHighlights < ActiveRecord::Migration
  def up
    drop_table :collection_highlights
  end

  def down
  end
end
