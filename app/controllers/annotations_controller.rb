require 'json'

class AnnotationsController < ApplicationController

  authorize_resource # ensures only people who have access via cancan (defined in ability.rb) can do this

  def index
    druid=params[:druid]
    @annotations=Annotation.includes(:user).where(:druid=>druid)

    respond_to do |format|
      format.js { render }
      format.xml  { render :xml => @annotations.to_xml }
      format.json { render :json=> @annotations.to_json }      
      format.html { render :partial => "catalog/annotation_list", :locals=>{:annotations=>@annotations}}
    end
  end
      
  def show
    
    @annotations=Annotation.includes(:user).where(:druid=>params[:id])
    @annotations.each do |annotation| # loop through all annotations
      annotation_hash=JSON.parse(annotation.json) # parse the annotation json into a ruby object
      annotation_hash[:editable]=can? :update, annotation 
      annotation_hash[:username]=(user_signed_in? && (annotation.user_id==current_user.id) ? "me" : annotation.user.to_s) # add the username (or "me" if current user)
      annotation_hash[:updated_at]=show_as_date(annotation.updated_at)
      annotation_hash[:id]=annotation.id
      annotation.json=annotation_hash.to_json # convert back to json
    end
    
    respond_to do |format|
      format.js   { render }
      format.xml  { render :xml => @annotations.to_xml }
      format.json { render :json=> @annotations.to_json }
      format.html { render :partial => "catalog/annotation_list", :locals=>{:annotations=>@annotations}}
    end
    
  end
  
  def create
    
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)

    @annotation=Annotation.create(:json=>annotation_json,:text=>annotation_hash['text'],:druid=>params[:druid],:user_id=>current_user.id)
    num_annotations=Annotation.where(:druid=>params[:druid]).count
    
    # in the json response, we add in the number of annotations into the json so we can update the badge on the badge with the success handler
    respond_to do |format|
      format.js   { render }
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.as_json.merge({'num_annotations'=>num_annotations}) }
      format.html { render :partial => "catalog/annotation_list", :locals=>{:annotations=>[@annotation]}}
    end
    
  end
  
  def update 
  
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)
    
    @annotation=Annotation.find(params[:id])
    @annotation.json=annotation_json
    @annotation.text=annotation_hash['text']
    @annotation.save

    respond_to do |format|
      format.js   { render }
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.to_json }
      format.html { render :partial => "catalog/annotation_list", :locals=>{:annotations=>[@annotation]}}      
    end
           
  end
  
  def destroy
    
    @annotation=Annotation.find(params[:id])
    druid=@annotation.druid
    @annotation.destroy
    num_annotations=Annotation.where(:druid=>druid).count

    # in the json response, we add in the number of annotations into the json so we can update the badge on the badge with the success handler    
    respond_to do |format|
      format.js   { render }
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.as_json.merge({'num_annotations'=>num_annotations}) }
      format.html { render :partial => "catalog/annotation_list", :locals=>{:annotations=>[@annotation]}}      
    end
    
  end
  
end
