# This migration comes from editstore (originally 20130711211606)
class CreateEditstoreFields < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_fields do |t|
        t.integer :project_id,:null=>false
        t.string  :name,:null=>false
        t.timestamps :null=>false
      end
      fields=%w{title description}
      fields.each do |field_name|
        field=Editstore::Field.new
        field.name=field_name
        field.project_id=1
        field.save
      end
    end
  end
end
