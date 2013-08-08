class UpdateFieldsInEditstore < ActiveRecord::Migration
  def up
    @connection=Editstore::Connection.connection
    project=Editstore::Project.where(:name=>'revs').first
    Editstore::Field.create(:name=>'city_sections_ssi',:project_id=>project.id)
    Editstore::Field.create(:name=>'states_ssi',:project_id=>project.id)
    Editstore::Field.create(:name=>'countries_ssi',:project_id=>project.id)
    Editstore::Field.create(:name=>'cities_ssi',:project_id=>project.id)
    Editstore::Field.where(:name=>'location_ssi').first.destroy
  end

  def down
  end
end
