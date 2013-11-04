class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :druid
      t.integer :visibility_value
      t.timestamps
    end
    add_index :items,:druid, :unique=>true
  end
end
