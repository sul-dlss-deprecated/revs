class CreateOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies do |t|
      t.string :field
      t.string :value
      t.integer :position
      t.timestamps
    end
    add_index :ontologies, :field
  end
end
