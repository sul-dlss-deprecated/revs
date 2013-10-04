# This migration comes from editstore (originally 20130814221827)
class AddErrorToChange < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      add_column :editstore_changes, :error, :string
    end
  end
end
