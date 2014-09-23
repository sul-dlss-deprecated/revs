# This migration comes from editstore (originally 20130710234514)
class CreateEditstoreProjects < ActiveRecord::Migration
    
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_projects do |t|
        t.string :name, :null=>false
        t.string :template, :null=>false
        t.timestamps
      end
      project=Editstore::Project.new
      project.id=1
      project.name='generic'
      project.template='generic'
      project.save
    end
  end
  
end
