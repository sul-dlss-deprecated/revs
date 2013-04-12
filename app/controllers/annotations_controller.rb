class AnnotationsController < ApplicationController
  
  def create
    
    Annotation.create(:annotation=>params[:annotation],:annotation_text=>params[:annotation_text],:druid=>params[:druid],:user_id=>current_user.id)
    
  end
  
end
