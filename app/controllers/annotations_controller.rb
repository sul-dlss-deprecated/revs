require 'json'

class AnnotationsController < ApplicationController

  authorize_resource # ensures only people who have access via cancan (defined in ability.rb) can do this

  before_filter :ajax_only, :only=>[:show_image_number]
  
  def index # all annotations, basically used as an API call
    @annotations=Annotation.all
    respond_to do |format|
      format.xml  { render :xml => @annotations.to_xml }
      format.json { render :json=> @annotations.to_json }      
      format.html { render :partial => "all", :locals=>{:annotations=>@annotations}}
    end
  end
  
  def index_by_druid # all annotations for a specific druid
    druid=params[:id]
    image_number=params[:image_number]
    @annotations=Annotation.for_image_with_user(druid,current_user,image_number)    
    respond_to do |format|
      format.xml  { render :xml => @annotations.to_xml }
      format.json { render :json=> @annotations.to_json }
      format.html { render :partial => "all", :locals=>{:annotations=>@annotations}}
    end
  end
  
  def show
    
    @annotation=Annotation.find(params[:id])
    respond_to do |format|
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.to_json }
      format.html { render :partial => "all", :locals=>{:annotations=>[@annotation]}}
    end
    
  end
  
  def create
    
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)

    @annotation=Annotation.create_new(:json=>annotation_json,:text=>annotation_hash['text'],:druid=>params[:druid],:user_id=>current_user.id,:image_number=>params[:n])
    num_annotations=Annotation.where(:druid=>params[:druid]).count
    
    # in the json response, we add in the number of annotations into the json so we can update the badge on the badge with the success handler
    respond_to do |format|
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.as_json.merge({'num_annotations'=>num_annotations}) }
      format.html { render :partial => "all", :locals=>{:annotations=>[@annotation]}}
    end
    
  end
  
  def update 
  
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)
    
    unless params[:id].nil?
    
      @annotation=Annotation.find(params[:id])
      @annotation.json=annotation_json
      @annotation.text=annotation_hash['text']
      @annotation.save

      respond_to do |format|
        format.xml  { render :xml => @annotation.to_xml }
        format.json { render :json=> @annotation.to_json }
        format.html { render :partial => "all", :locals=>{:annotations=>[@annotation]}}      
      end

    else
      
      render :nothing=>true
      
    end
    
    
  end
  
  def destroy
    
    @annotation=Annotation.find(params[:id])
    @druid=@annotation.druid
    @annotation.destroy
    @num_annotations=Annotation.where(:druid=>@druid).count

    # in the json response, we add in the number of annotations into the json so we can update the badge on the badge with the success handler    
    respond_to do |format|
      format.js   { render }
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.as_json.merge({'num_annotations'=>@num_annotations}) }
      format.html { render :partial => "all", :locals=>{:annotations=>[@annotation]}}      
    end
    
  end
  
  # an ajax call to get a new image to annotate for a multi-image object
  def show_image_number
    @druid=params[:id]
    @image_number=params[:image_number].to_i
    @document = SolrDocument.find(@druid)
    render :partial=>'annotate_image', :locals=>{:image_number=>@image_number}
  end
  
end
