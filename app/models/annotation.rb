class Annotation < ActiveRecord::Base
  
  belongs_to :user  
  attr_accessible :annotation_text, :annotation, :user_id, :druid

end
