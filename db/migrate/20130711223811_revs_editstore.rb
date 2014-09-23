class RevsEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection        
      project=Editstore::Project.new
      project.name='revs'
      project.template='revs'
      project.save
      fields=%w{title_tsi pub_year_isim format_ssim description_tsim people_ssim subjects_ssim marque_ssim entrant_ssi current_owner_tsi venue_ssi track_ssi event_ssi location_ssi group_class_tsi race_data_tsi vehicle_markings_tsi photographer_ssi model_year_ssim model_ssim}
      fields.each do |field_name|
        field=Editstore::Field.new
        field.name=field_name
        field.project_id=project.id
        field.save
      end
    end
  end
end
