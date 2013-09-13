class UpdateFieldsInEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.where(:name=>'Revs').first
      Editstore::Field.create(:name=>'city_sections_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'states_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'countries_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'cities_ssi',:project_id=>project.id)
      Editstore::Field.where(:name=>'location_ssi').first.destroy
    end
  end
end
