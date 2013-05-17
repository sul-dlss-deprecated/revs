class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name
      t.timestamps
    end
    # note: role names should be stored in CamelizedFormat
    # role names are referenced in the 'Ability' model
    Role.create(:id=>1,:name=>'User')
    Role.create(:id=>2,:name=>'Curator')    
    Role.create(:id=>3,:name=>'Admin')    
  end
end
