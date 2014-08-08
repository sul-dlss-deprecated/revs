class AddPrivateCommentsToFlags < ActiveRecord::Migration
  def change
    add_column :flags,:private_comment,:text
  end
end
