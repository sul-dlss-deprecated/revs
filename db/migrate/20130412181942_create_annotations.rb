class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.integer :user_id
      t.text :annotation
      t.string :annotation_text
      t.string :druid
      t.timestamps
    end
  end
end
