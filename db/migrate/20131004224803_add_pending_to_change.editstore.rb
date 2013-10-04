# This migration comes from editstore (originally 20131004224346)
class AddPendingToChange < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      add_column :editstore_changes, :pending, :boolean, :default=>false
    end
  end
end
