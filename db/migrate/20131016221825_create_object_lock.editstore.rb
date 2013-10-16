# This migration comes from editstore (originally 20131015203809)
class CreateObjectLock < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_object_locks do |t|
        t.string :druid, :null=>false
        t.datetime :locked
        t.timestamps
      end
    end
  end
end
