class SwitchSortOrderToPosition < ActiveRecord::Migration
  def change
  	 add_column :saved_items, :position, :integer
  	 remove_column :saved_items, :sort_order
  end

end
