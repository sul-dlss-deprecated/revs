class Annotation < ActiveRecord::Base
   attr_accessible :annotation_text, :annotation, :user_id, :druid
end
