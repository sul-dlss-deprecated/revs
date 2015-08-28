class AddImageNumberToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations,:image_number,:integer, :default=>0, :null=>true
  end
end
