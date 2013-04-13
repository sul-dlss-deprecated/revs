class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.integer :user_id
      t.text :json
      t.string :text
      t.string :druid
      t.timestamps
    end
    add_index :annotations, :druid
    add_index :annotations, :user_id
  end
end
