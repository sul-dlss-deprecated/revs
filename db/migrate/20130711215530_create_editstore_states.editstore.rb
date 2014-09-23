# This migration comes from editstore (originally 20130711173100)
class CreateEditstoreStates < ActiveRecord::Migration
  def change
    if Editstore.run_migrations?
      @connection=Editstore::Connection.connection
      create_table :editstore_states do |t|
        t.string  :name, :null=>false
        t.timestamps
      end
      states=['wait','ready','in process','error','applied','complete']
      n=1
      states.each do |state_name|
        state=Editstore::State.new
        state.id=n
        state.name=state_name
        state.save
        n+=1        
      end
    end
  end
end
