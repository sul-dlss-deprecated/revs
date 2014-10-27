class AnnotationConvertColumn < ActiveRecord::Migration
  def up
    change_column :annotations, :text,  :text, :limit=>nil
  end

  def down
    change_column :annotations, :text,  :string
  end
end
