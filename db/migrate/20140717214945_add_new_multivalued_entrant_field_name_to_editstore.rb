class AddNewMultivaluedEntrantFieldNameToEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.where(:name=>'revs',:template=>'revs').first
      Editstore::Field.create(:name=>'entrant_ssim',:project_id=>project.id)
    end
  end
end
