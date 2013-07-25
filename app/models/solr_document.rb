# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document
  
  include ActivesolrHelper
  extend ActivesolrHelper::ClassMethods
  
  include DateHelpers
        
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


    # The following shows how to setup this blacklight document to display marc documents
    extension_parameters[:marc_source_field] = :marc_display
    extension_parameters[:marc_format_type] = :marcxml
    use_extension( Blacklight::Solr::Document::Marc) do |document|
      document.key?( :marc_display  )
    end
  
  self.unique_key = 'id'
  
  ########################
  # The methods below need to be set to use Activesolr                             
  # a hash of attribute names to solr document field names, used by Activesolr to create automatic setters and getters
  # attributes in lowercase symbols; set to a hash with :field denothing the solr field name, and the optional :default denoting the value to set if solr field is blank
  def self.use_editstore
    true # set to true to propogate changes to editstore when the .save method is called
  end
  
  def self.field_mappings
    {
      :title=>{:field=>'title_tsi',:default=>'Untitled'},
      :description=>{:field=>'description_tsim'},
      :photographer=>{:field=>'photographer_ssi'},
      :years=>{:field=>'pub_year_isim'},
      :full_date=>{:field=>'pub_date_ssi'},
      :people=>{:field=>'people_ssim'},
      :subjects=>{:field=>'subjects_ssim'},
      :location=>{:field=>'location_ssi'},
      :formats=>{:field=>'format_ssim'},
      :identifier=>{:field=>'source_id_ssi'},
      :production_notes=>{:field=>'prod_notes_tsi'},
      :institutional_notes=>{:field=>'inst_notes_tsi'},
      :metadata_sources=>{:field=>'metadata_sources_tsi'},
      :has_more_metadata=>{:field=>'has_more_metadata_ssi'},
      :vehicle_markings=>{:field=>'vehicle_markings_tsi'},
      :marque=>{:field=>'marque_ssim'},
      :vehicle_model=>{:field=>'model_ssim'},
      :model_year=>{:field=>'model_year_ssim'},
      :current_owner=>{:field=>'current_owner_ssi'},
      :entrant=>{:field=>'entrant_ssi'},
      :venue=>{:field=>'venue_ssi'},
      :track=>{:field=>'track_ssi'},
      :event=>{:field=>'event_ssi'},
      :group_class=>{:field=>'group_class_tsi'},
      :race_data=>{:field=>'race_data_tsi'},
      :priority=>{:field=>'priority_isi',:default=>0},
      :collections=>{:field=>'is_member_of_ssim'},
      :collection_names=>{:field=>'collection_ssim'},
      }  
  end
  
  # you can configure a callback method to execute if any of these fields are changed
  # set the solr field as the key, and the method name as the value; the method will receive the solr field being updated and its new value
  # if you don't have any callbacks needed, just set an empty hash
  def self.field_update_callbacks
    {
      :pub_date_ssi=>:update_date_fields,
      :pub_year_isim=>:update_date_fields,
      :pub_year_single_isi=>:update_date_fields
    }
  end
  
  # if the user updates one of the date fields, we'll run some computations to update the others as needed
  # this method is set as a callback when one of the date fields is updated
  def update_date_fields(field_name,new_value)
    case field_name.to_sym
      when :pub_year_isim # if the user has updated a multivalued year field, we need to blank out the full date, since its no longer valid, and set the single year field if we have one year
        remove_field('pub_date_ssi')
        self['pub_date_ssi']=nil
        if new_value.class == Array and new_value.size == 1
          update_solr('pub_year_single_isi','set',new_value)
          self['pub_year_single_isi']=new_value
        else
          remove_field('pub_year_single_isi')
          self['pub_year_single_isi']=nil
        end
      when :pub_year_single_isi  # if the user has updated a year field, we need to blank out the full date, since its no longer valid, and set the years field
        remove_field('pub_date_ssi')
        update_solr('pub_year_isim','set',new_value)
        self['pub_year_isim']=new_value
      when :pub_date_ssi # if the user has updated a date field, we need to set the years appropriately
        new_value=new_value.first if new_value.class == Array
        full_date=get_full_date(new_value)
        if full_date # if it's a valid full date, extract the year into the single and multi-valued year fields
          update_solr('pub_year_isim','set',full_date.year.to_s)
          update_solr('pub_year_single_isi','set',full_date.year.to_s)
          self['pub_year_single_isi']=full_date.year.to_s
          self['pub_year_isim']=full_date.year.to_s
        else # if it's not a valid date, clear the year fields
          remove_field('pub_year_isim')
          remove_field('pub_date_single_isi')
          self['pub_year_single_isi']=nil
          self['pub_year_isim']=nil
        end
    end    
  end
  
  # this method is used to determine if an object is valid before it is saved
  # iterate through all unsaved edits, and check based on solr field, add to @errors to make something invalid
  def valid?
    
    @errors=[]
    
    unsaved_edits.each do |solr_field_name,value| 

      case solr_field_name.to_sym
        when :pub_date_ssi
          @errors << 'Date must be in the format MM/DD/YYYY' if (!self.class.blank_value?(value) && get_full_date(value) == false)
        when :pub_year_isim,:pub_year_single_isi
          years=self.class.to_array(value)
          @errors << 'A year must be after 1800 up until this year and must be in the format YYYY' if (!self.class.blank_value?(years) && !years.all?{|new_value| is_valid_year?(new_value)})
      end
    
    end
    
    return @errors.size == 0

  end

  ######################
  # we need a custom getter/setter for the description field because
  # for some reason, we have description as a multivalued field, but we really only need it to be a single valued field
  def description 
    desc=self['description_tsim']
    desc.class == Array ? desc.first : desc
  end
  def description=(value)
    set_field('description_tsim',value.strip)
  end
  ######################
  
  #####################
  # provides the equivalient of an ActiveRecord has_one relationship with collection
  # Return a SolrDocument object of the parent collection of an item
  def collection
    return nil unless is_item?
    @collection ||= SolrDocument.new(
                      Blacklight.solr.select(
                        :params => {
                          :fq => "#{SolrDocument.unique_key}:\"#{self[blacklight_config.collection_member_identifying_field].first}\""
                        }
                      )["response"]["docs"].first
                    )
  end
  #  
  ######################
  
  ######################
  # provides the equivalent of an ActiveRecord has_many relationship with flags, annotations, images and siblings
  def flags
    Flag.includes(:user).where(:druid=>id)
  end

  def annotations(user)
    Annotation.for_image_with_user(id,user)
  end

  # Return a CollectionMembers object of all of the siblings of a collection member (including self)
  def siblings(params={})
    return nil unless is_item?

    rows=params[:rows] || blacklight_config.collection_member_grid_items
    start=params[:start] || 0
    @siblings ||= CollectionMembers.new(
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

  def images(size=:default)
    return nil unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Revs::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      "#{stacks_url}/#{self["id"]}/#{image_id}#{SolrDocument.image_dimensions[size]}"
    end
  end

  # Return a CollectionMembers object of just the members of a collection, and cache the result in the object so we can use on the page over again
  def collection_members(params={})
    return nil unless is_collection?
    @collection_members ||= get_members(params)
  end

  # this can be called when you don't want the result to be cached in the object (so you can update the counts or start for paging)
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
  ###################
  
  
  def has_vehicle_metadata?
    return true if
      !self.current_owner.blank? || !self.marque.blank? || !self.vehicle_markings.blank? || !self.group_class.blank?
  end

  def has_race_metadata?
    return true if
      !self.entrant.blank? || !self.venue.blank? || !self.track.blank? || !self.event.blank? || !self.race_data.blank?
  end

  def is_collection?
    !self.formats.blank? && self.formats.include?('collection')
  end

  def is_item?
    !self.collections.blank?
  end
  
  def first_item
    return nil unless is_collection?
    self.collection_members(:rows=>1,:start=>0).first
  end
  
  # gives you the representative image of the collection
  def first_image
    return nil unless is_collection?
    first_item.images(:large).first
  end
  
  # gives you the current top priority number for item sorting for the given collection
  def current_top_priority
    return nil unless is_collection?
    first_item.priority.to_i
  end
  
  # if an item, set it to be the top priority item for that particular collection
  def set_top_priority
    return false unless is_item?
    new_priority=collection.current_top_priority + 1
    set_field('priority_isi',new_priority)
    self['priority_isi']=new_priority
    return true
  end
  
   ##################################################################
   # CLASS LEVEL METHODS
   # Return an Array of all collection type SolrDocuments
   def self.all_collections
     @all_collections ||= Blacklight.solr.select(
       :params => {
         :fq => "#{self.config.collection_identifying_field}:\"#{self.config.collection_identifying_value}\"",
         :rows => "10000"
       }
     )["response"]["docs"].map do |document|
       SolrDocument.new(document)
     end
   end

  def self.total_images
    items=Blacklight.solr.get 'select',:params=>{:q=>'-format_ssim:collection'}      
    return items['response']['numFound']
  end
  
  def self.image_dimensions
    options = {:default => "_square",
               :large   => "_thumb" }
  end

  def self.bulk_update(params) # apply update to the supplied field with the supplied value to the specified list of druids; returns false if something didn't work
    
    selected_druids=params[:selected_druids]
    attribute=params[:attribute]
    new_value=params[:new_value]
    
    valid=true
        
    selected_druids.each do |druid|
    
      # load item and grab old values
      item=self.find(druid)
      item.send("#{attribute}=",new_value) # this sets the attribute
      valid = item.save # if true, we have successfully updated solr
      break unless valid # stop if we are not valid
      
    end
          
    return valid
    
  end

  private
  def self.config
    CatalogController.blacklight_config  
  end
  
  def blacklight_config
    self.class.config
  end
  
end
