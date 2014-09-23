class UpdateFieldsInEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.where(:name=>'revs').first
      if project
        fields=%w{city_sections_ssi states_ssi countries_ssi cities_ssi}
        fields.each do |field_name|
          field=Editstore::Field.new
          field.name=field_name
          field.project_id=project.id
          field.save
        end
        Editstore::Field.where(:name=>'location_ssi',:project_id=>project.id).first.destroy
      end
    end
  end
end
