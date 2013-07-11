# This migration comes from editstore (originally 20130710234514)
class CreateEditstoreProjects < ActiveRecord::Migration
    
  def change
    @connection=Editstore::Connection.connection
    create_table :editstore_projects do |t|
      t.string :name, :null=>false
      t.string :template, :null=>false
      t.timestamps
    end
    Editstore::Project.create(:id=>1,:name=>'generic',:template=>'generic')
    
  end
  
end
