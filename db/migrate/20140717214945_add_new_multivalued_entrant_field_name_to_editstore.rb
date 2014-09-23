class AddNewMultivaluedEntrantFieldNameToEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.where(:name=>'revs',:template=>'revs').first
      if project
        field=Editstore::Field.new
        field.name='entrant_ssim'
        field.project_id=project.id
        field.save
      end
    end
  end
end
