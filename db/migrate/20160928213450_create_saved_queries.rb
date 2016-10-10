class CreateSavedQueries < ActiveRecord::Migration
  def change
    create_table :saved_queries do |t|
      t.string :title, null: false
      t.string :slug
      t.text   :description
      t.string :query, size: 500, null: false
      t.string :thumbnail, size: 500
      t.string :visibility
      t.boolean :active, default: true
      t.integer :position
      t.integer :user_id
      t.integer  :views, null: false, default: 0

      t.timestamps null: false
    end
    add_index :saved_queries,:user_id
  end
end
