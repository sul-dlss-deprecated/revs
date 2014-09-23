class AddFieldToRevsEditstore < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.where(:name=>'revs').first
      if project
        field=Editstore::Field.new
        field.name='pub_date_ssi'
        field.project_id=project.id
        field.save
      end
    end
  end
end
