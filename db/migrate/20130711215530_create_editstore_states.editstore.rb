# This migration comes from editstore (originally 20130711173100)
class CreateEditstoreStates < ActiveRecord::Migration
  def change
    @connection=Editstore::Connection.connection
    create_table :editstore_states do |t|
      t.string  :name, :null=>false
      t.timestamps
    end
    Editstore::State.create(:id=>1,:name=>'wait')
    Editstore::State.create(:id=>2,:name=>'ready')
    Editstore::State.create(:id=>3,:name=>'in process')
    Editstore::State.create(:id=>4,:name=>'error')
    Editstore::State.create(:id=>5,:name=>'applied')
    Editstore::State.create(:id=>6,:name=>'complete')    
  end
end
