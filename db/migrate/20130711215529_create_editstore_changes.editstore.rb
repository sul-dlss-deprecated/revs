# This migration comes from editstore (originally 20130711172833)
class CreateEditstoreChanges < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_changes do |t|
        t.integer :project_id, :null=>false
        t.string  :field, :null=>false
        t.string  :druid, :null=>false
        t.text    :old_value
        t.text    :new_value
        t.string  :operation, :null=>false
        t.integer :state_id, :null=>false
        t.text    :client_note
        t.timestamps
      end
    end
  end
end
