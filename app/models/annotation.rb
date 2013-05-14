require 'rest_client'

class Annotation < ActiveRecord::Base
  
  belongs_to :user  
  attr_accessible :text, :json, :user_id, :druid

  after_create :add_annotation_to_solr
  after_update :update_annotation_in_solr

  validates :druid, :is_druid=>true
  validates :text, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }

  def add_annotation_to_solr

    druid=self.druid
    text=self.text.gsub('"','\"')

    RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "[{\"id\":\"#{druid}\",\"annotations_tsim\":{\"add\":\"#{text}\"}}]",:content_type => :json, :accept=>:json
    
  end
  
  def update_annotation_in_solr
    
    # get all annotations for this image and update the solr document (its easier than trying to figure out exactly which annotation changed)
    
    druid=self.druid
    
    annotations=Annotation.where(:druid=>druid)
    text_array = annotations.map {|annotation| annotation.text.gsub('"','\"')}
    
    RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "[{\"id\":\"#{druid}\",\"annotations_tsim\":{\"set\":[\"#{text_array.join('","')}\"]}}]", :content_type => :json, :accept=>:json
          
  end
    
end
