class AddSourceId < ActiveRecord::Migration
  def change
    add_column :annotations, :source_id, :string
    add_column :flags, :source_id, :string
    add_column :items, :source_id, :string
    add_column :saved_items, :source_id, :string
  end
end
