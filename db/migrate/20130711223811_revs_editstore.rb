class RevsEditstore < ActiveRecord::Migration
  def up
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      project=Editstore::Project.create(:name=>'revs',:template=>'revs')
      Editstore::Field.create(:name=>'title_tsi',:project_id=>project.id)
      Editstore::Field.create(:name=>'pub_year_isim',:project_id=>project.id)
      Editstore::Field.create(:name=>'format_ssim',:project_id=>project.id)
      Editstore::Field.create(:name=>'description_tsim',:project_id=>project.id)
      Editstore::Field.create(:name=>'people_ssim',:project_id=>project.id)
      Editstore::Field.create(:name=>'subjects_ssim',:project_id=>project.id)
      Editstore::Field.create(:name=>'marque_ssim',:project_id=>project.id)
      Editstore::Field.create(:name=>'entrant_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'current_owner_tsi',:project_id=>project.id)
      Editstore::Field.create(:name=>'venue_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'track_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'event_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'location_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'group_class_tsi',:project_id=>project.id)
      Editstore::Field.create(:name=>'race_data_tsi',:project_id=>project.id)
      Editstore::Field.create(:name=>'vehicle_markings_tsi',:project_id=>project.id)
      Editstore::Field.create(:name=>'photographer_ssi',:project_id=>project.id)
      Editstore::Field.create(:name=>'model_year_ssim',:project_id=>project.id)
      Editstore::Field.create(:name=>'model_ssim',:project_id=>project.id)
    end
  end
end
