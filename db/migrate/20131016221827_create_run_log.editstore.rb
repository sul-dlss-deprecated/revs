# This migration comes from editstore (originally 20131016183057)
class CreateRunLog < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_run_logs do |t|
        t.integer :total_druids
        t.integer :total_changes
        t.integer :num_errors
        t.integer :num_pending
        t.string :note
        t.datetime :started
        t.datetime :ended
        t.timestamps
      end
    end
  end
end
