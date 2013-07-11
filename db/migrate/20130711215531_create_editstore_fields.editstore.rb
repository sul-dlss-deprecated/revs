# This migration comes from editstore (originally 20130711211606)
class CreateEditstoreFields < ActiveRecord::Migration
  def change
    @connection=Editstore::Connection.connection
    create_table :editstore_fields do |t|
      t.integer :project_id,:null=>false
      t.string  :name,:null=>false
      t.timestamps
    end
    Editstore::Field.create(:id=>1,:name=>'title',:project_id=>'1')
    Editstore::Field.create(:id=>1,:name=>'description',:project_id=>'1')    
  end
end
