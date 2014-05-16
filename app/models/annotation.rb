require 'rest_client'

class Annotation < WithSolrDocument
  
  belongs_to :user  
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
  
  attr_accessible :text, :json, :user_id, :druid
  
  after_create :add_annotation_to_solr
  after_update :update_annotation_in_solr
  after_destroy :update_annotation_in_solr

  validates :druid, :is_druid=>true
  validates :text, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  
   ANNOTATION_ALL = 'all'
   ANNOTATION_NONE = 'none'

  # pass in a druid and a user and get the annotations for that image, with the appropriate json additions required for display annotations on the image
  def self.for_image_with_user(druid,user)
    annotations=Annotation.includes(:user).where(:druid=>druid,'users.active'=>true).order('annotations.created_at desc')
    annotations.each do |annotation| # loop through all annotations
      annotation_hash=JSON.parse(annotation.json) # parse the annotation json into a ruby object
      annotation_hash[:editable]=user ? user.can?(:update, annotation) : false 
      annotation_hash[:username]=(user && annotation.user_id==user.id) ? "me" : annotation.user.to_s # add the username (or "me" if current user)
      annotation_hash[:updated_at]=annotation.updated_at.strftime('%B %d, %Y')  
      annotation_hash[:id]=annotation.id
      annotation.json=annotation_hash.to_json # convert back to json
    end
    return annotations
  end
  
  def self.show_all
    return  ANNOTATION_ALL
  end
  
  def self.show_none
    return  ANNOTATION_NONE
  end
  
  def add_annotation_to_solr
    solr_document.add_field('annotations_tsim',text)
  end
  
  # to update an annotation, just get all annotations for this image and update the solr document (its easier than trying to figure out exactly which annotation changed)
  def update_annotation_in_solr    
    self.class.add_to_solr_for_druid(self.druid)        
  end
  
  # this is a class level method so we can call it easily for any given druid (e.g. after an indexing operation) without having to load the object first
  def self.add_to_solr_for_druid(druid)
       
    annotations=Annotation.where(:druid=>druid)
    text_array = annotations.map {|annotation| annotation.text}    
    SolrDocument.find(druid).set_field('annotations_tsim',text_array)
    
  end
  
    
end
