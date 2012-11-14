# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document

  self.unique_key = 'id'

  def collection?
    self.has_key?(blacklight_config.collection_identifying_field) and 
      self[blacklight_config.collection_identifying_field] == blacklight_config.collection_identifying_value
  end
  
  def collection_member?
    self.has_key?(blacklight_config.collection_member_identifying_field) and 
      !self[blacklight_config.collection_member_identifying_field].blank?
  end
  
  def collection_members
    return nil unless collection?
    @collection_members ||= CollectionMembers.new(Blacklight.solr.select({:fq=>"#{blacklight_config.collection_member_identifying_field}:\"#{self[SolrDocument.unique_key]}\"", :rows=>"20"}))
  end
  
  def images(size=:default)
    return nil unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Revs::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      "#{stacks_url}/#{self["id"]}/#{image_id}#{SolrDocument.image_dimensions[size]}"
    end
  end
  
  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )
     
  def self.image_dimensions
    options = {:default => "_square",
               :large   => "_thumb" }
  end
                         
  private
  
  def blacklight_config
    CatalogController.blacklight_config
  end
end
