class AddFieldToRevsEditstore < ActiveRecord::Migration
  def change
    project=Editstore::Project.where(:name=>'revs')
    Editstore::Field.create(:name=>'pub_date_ssi',:project_id=>project.first.id)
  end
end
