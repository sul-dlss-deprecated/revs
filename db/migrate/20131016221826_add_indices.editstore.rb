# This migration comes from editstore (originally 20131015205757)
class AddIndices < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      add_index(:editstore_changes, :project_id)
      add_index(:editstore_changes, :druid)
      add_index(:editstore_changes, :state_id)
      add_index(:editstore_fields, :project_id)
      add_index(:editstore_object_locks, :druid)
      add_index(:editstore_object_locks, :locked)
    end
  end

  def down
  end
end
