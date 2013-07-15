# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document

  self.unique_key = 'id'

  def flags
    Flag.includes(:user).where(:druid=>id)
  end

  def annotations(user)
    Annotation.for_image_with_user(id,user)
  end

  def title
    self[:title_tsi] || "Untitled"
  end

  def description
    self[blacklight_config.collection_description_field.to_sym]
  end

  def photographer
    self[:photographer_ssi]
  end

  def full_date
    self[:pub_date_ssi]
  end

  def years
    self[:pub_year_isim]
  end

  def people
    self[:people_ssim]
  end

  def subjects
    self[:subjects_ssim]
  end

  def location
    self[:location_ssi]
  end

  def formats
    self[:format_ssim]
  end

  def identifier
    self[:source_id_ssi]
  end

  def institutional_notes
    self[:inst_notes_tsi]
  end

  def production_notes
    self[:prod_notes_tsi]
  end

  def metadata_sources
    self[:metadata_sources_tsi]
  end

  def has_more_metadata
    self[:has_more_metadata_ssi]
  end

  def vehicle_markings
    self[:vehicle_markings_tsi]
  end

  def marque
    self[:marque_ssim]
  end

  def vehicle_model
    self[:model_ssim]
  end

  def model_year
    self[:model_year_ssim]
  end

  def current_owner
    self[:current_owner_ssi]
  end

  def entrant
    self[:entrant_ssi]
  end

  def venue
    self[:venue_ssi]
  end

  def track
    self[:track_ssi]
  end

  def event
    self[:event_ssi]
  end

  def group_class
    self[:group_class_tsi]
  end

  def race_data
    self[:race_data_tsi]
  end

  def has_vehicle_metadata?
    return true if
      self.current_owner || self.marque || self.vehicle_markings || self.group_class
  end

  def has_race_metadata?
    return true if
      self.entrant || self.venue || self.track || self.event || self.race_data
  end

  def collection_names
    self[blacklight_config.collection_member_collection_title_field.to_sym]
  end

  def collection?
    self.has_key?(blacklight_config.collection_identifying_field) and
      self[blacklight_config.collection_identifying_field].include?(blacklight_config.collection_identifying_value)
  end

  def collection_member?
    self.has_key?(blacklight_config.collection_member_identifying_field) and
      !self[blacklight_config.collection_member_identifying_field].blank?
  end

  # Return a SolrDocument object of the parent collection of a collection member
  def collection
    return nil unless collection_member?
    @collection ||= SolrDocument.new(
                      Blacklight.solr.select(
                        :params => {
                          :fq => "#{SolrDocument.unique_key}:\"#{self[blacklight_config.collection_member_identifying_field].first}\""
                        }
                      )["response"]["docs"].first
                    )
  end

  # Return a CollectionMembers object of just the members of a collection, and cache the result in the object so we can use on the page over again
  def collection_members(params={})
    return nil unless collection?
    @collection_members ||= get_members(params)
  end

  # this can be called when you don't want the result to be cached in the object (so you update the counts or start for paging)
  def get_members(params={})

    rows=params[:rows] || blacklight_config.collection_member_grid_items
    start=params[:start] || 0
    return CollectionMembers.new(
                              Blacklight.solr.select(
                                :params => {
                                  :fq => "#{blacklight_config.collection_member_identifying_field}:\"#{self[SolrDocument.unique_key]}\"",
                                  :sort=> "priority_isi desc",
                                  :rows => rows.to_s,
                                  :start => start.to_s
                                }
                              )
                            )
  end
  
  def first_item
    self.collection_members(:rows=>1,:start=>0).first
  end
  
  # gives you the representative image of the collection
  def first_image
    first_item.images(:large).first
  end
  
  # gives you the current top priority number for item sorting
  def current_top_priority
    first_item['priority_isi'] || 0
  end
  
  # Return a CollectionMembers object of all of the siblings of a collection member (including self)
  def collection_siblings(params={})
    return nil unless collection_member?

    rows=params[:rows] || blacklight_config.collection_member_grid_items
    start=params[:start] || 0
    @collection_siblings ||= CollectionMembers.new(
                               Blacklight.solr.select(
                                 :params => {
                                   :fq => "#{blacklight_config.collection_member_identifying_field}:\"#{self[blacklight_config.collection_member_identifying_field].first}\"",
                                   :sort=> "priority_isi desc",
                                   :rows => rows.to_s,
                                  :start => start.to_s
                                 }
                               )
                             )
  end

  # Return an Array of collection SolrDocuments
  def all_collections
    @all_collections ||= Blacklight.solr.select(
      :params => {
        :fq => "#{blacklight_config.collection_identifying_field}:\"#{blacklight_config.collection_identifying_value}\"",
        :rows => "1000"
      }
    )["response"]["docs"].map do |document|
      SolrDocument.new(document)
    end
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
                         :title => "title_tsi",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format_ssim"
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
