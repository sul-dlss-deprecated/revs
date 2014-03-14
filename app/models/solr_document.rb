######################## -*- encoding : utf-8 -*-
require 'revs-utils'

class SolrDocument

  include Blacklight::Solr::Document
  
  include ActivesolrHelper
  extend ActivesolrHelper::ClassMethods
  
  include VisibilityHelper
  include DateHelper
  include SolrQueryHelper     
 
  extend Revs::Utils
      
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
  #  set :editstore to false if you don't want the change to propogate to DOR in any scenario
  
  def self.use_editstore
    Revs::Application.config.use_editstore # set to true to propogate changes to editstore when the .save method is called
  end
  
  # map visibility values stored in solr and the database to what they mean
  def self.visibility_mappings
    { :hidden =>  '0',
      :visible => '1',
      :preview => '2'
    }
  end
  
  def self.field_mappings
    {
      :title=>{:field=>'title_tsi',:default=>'Untitled'},
      :description=>{:field=>'description_tsim', :multi_valued => true},
      :photographer=>{:field=>'photographer_ssi'},
      :years=>{:field=>'pub_year_isim', :multi_valued => true},
      :single_year=>{:field=>'pub_year_single_isi'},
      :full_date=>{:field=>'pub_date_ssi'},
      :people=>{:field=>'people_ssim', :multi_valued => true},
      :subjects=>{:field=>'subjects_ssim', :multi_valued => true},
      :city_section=>{:field=>'city_sections_ssi'},
      :city=>{:field=>'cities_ssi'},
      :state=>{:field=>'states_ssi'},
      :country=>{:field=>'countries_ssi'},
      :formats=>{:field=>'format_ssim', :multi_valued => true},
      :identifier=>{:field=>'source_id_ssi'},
      :production_notes=>{:field=>'prod_notes_tsi'},
      :institutional_notes=>{:field=>'inst_notes_tsi'},
      :metadata_sources=>{:field=>'metadata_sources_tsi'},
      :has_more_metadata=>{:field=>'has_more_metadata_ssi'},
      :vehicle_markings=>{:field=>'vehicle_markings_tsi'},
      :marque=>{:field=>'marque_ssim', :multi_valued => true},
      :vehicle_model=>{:field=>'model_ssim', :multi_valued => true},
      :model_year=>{:field=>'model_year_ssim', :multi_valued => true},
      :current_owner=>{:field=>'current_owner_ssi'},
      :entrant=>{:field=>'entrant_ssi'},
      :venue=>{:field=>'venue_ssi'},
      :track=>{:field=>'track_ssi'},
      :event=>{:field=>'event_ssi'},
      :group_class=>{:field=>'group_class_tsi'},
      :race_data=>{:field=>'race_data_tsi'},
      :priority=>{:field=>'priority_isi',:default=>0,:editstore=>false},
      :collections=>{:field=>'is_member_of_ssim', :multi_valued => true},
      :collection_names=>{:field=>'collection_ssim', :multi_valued => true,:editstore=>false},
      :highlighted=>{:field=>'highlighted_ssi',:editstore=>false},
      :visibility_value=>{:field=>'visibility_isi',:editstore=>false},
      :copyright=>{:field=>'copyright_ss',:editstore=>false,:default=>"Courtesy of the Revs Institute for Automotive Research. All rights reserved unless otherwise indicated."},
      :use_and_reproduction=>{:field=>'use_and_reproduction_ss',:editstore=>false,:default=>"Users must contact the The Revs Institute for Automotive Research for re-use and reproduction information."},
      }  
  end

  # you can configure a callback method to execute if any of these fields are changed
  # set the solr field as the key, and the method name as the value; the method will receive the solr field being updated and its new value
  # if you don't have any callbacks needed, just set an empty hash
  # NOTE: the callbacks occur on "SAVE", not immediately when a value is set
  def self.field_update_callbacks
    {
      :pub_date_ssi=>:update_date_fields,
      :pub_year_isim=>:update_date_fields,
      :pub_year_single_isi=>:update_date_fields,
    }
  end
  
  # a helper that makes it easy to show the document location as a single string
  def location
    [city_section,city,state,country].reject(&:blank?).join(', ')
  end
  
  # if the user updates one of the date fields, we'll run some computations to update the others as needed
  # this method is set as a callback when one of the date fields is updated
  def update_date_fields(field_name,new_value)
    case field_name.to_sym
      when :pub_year_isim # if the user has updated a multivalued year field, we need to blank out the full date, since its no longer valid, and set the single year field if we have only one year
        immediate_remove('pub_date_ssi')
        if new_value.class == Array && new_value.size == 1
          immediate_update('pub_year_single_isi',new_value.first)
        else
          immediate_remove('pub_year_single_isi')
        end
      when :pub_year_single_isi  # if the user has updated a year field, we need to blank out the full date, since its no longer valid, and set the years field
        immediate_remove('pub_date_ssi')
        immediate_update('pub_year_isim',new_value)
      when :pub_date_ssi # if the user has updated a date field, we need to set the years appropriately
        new_value=new_value.first if new_value.class == Array
        full_date=get_full_date(new_value)
        if full_date # if it's a valid full date, extract the year into the single and multi-valued year fields
          immediate_update('pub_year_single_isi',full_date.year.to_s)
          immediate_update('pub_year_isim',full_date.year.to_s)
        else # if it's not a valid date, clear the year fields
          immediate_remove('pub_year_isim')
          immediate_remove('pub_year_single_isi')
        end
    end    
  end
  
  # this method is used to determine if an object is valid before it is saved
  # iterate through all unsaved edits, and check based on solr field, add to @errors to make something invalid
  def valid?
    
    @errors=[]
    
    unsaved_edits.each do |solr_field_name,value| 

      case solr_field_name.to_sym
        when :model_year_ssim
          model_years=self.class.to_array(value)
          @errors << 'Model years must be after 1850 up until this year and must be in the format YYYY'  if (!self.class.blank_value?(model_years) && !model_years.all?{|new_value| is_valid_year?(new_value,1850)})
        when :pub_date_ssi
          @errors << 'Date must be in the format MM/DD/YYYY' if (!self.class.blank_value?(value) && get_full_date(value) == false)
        when :pub_year_isim,:pub_year_single_isi
          years=self.class.to_array(value)
          @errors << 'A year must be after 1800 up until this year and must be in the format YYYY' if (!self.class.blank_value?(years) && !years.all?{|new_value| is_valid_year?(new_value,1800)})
        when :visibility_isi
          @errors << 'Visibility value not_valid' unless SolrDocument.visibility_mappings.values.include? value.to_s
      end
    
    end
    
    return @errors.size == 0

  end

  ######################
  # we need a custom getter for the description field because
  # for some reason, we have description as a multivalued solr field, but we really only need it to be a single valued field
  def description 
    desc=self['description_tsim']
    desc.class == Array ? desc.first : desc
  end
  ######################
  
  #####################
  # provides the equivalent of an ActiveRecord has_one relationship with collection
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
  # provides the equivalent of an ActiveRecord has_many relationship with flags, annotations, edits, images and siblings
  def flags
    @flags ||= Flag.includes(:user).where(:druid=>id).where(:'users.active'=>true).order('flags.created_at desc')
  end

  def saved_items
    @saved_items ||= SavedItem.includes(:gallery).where(:druid=>id).order('saved_items.created_at desc')
  end

  def annotations(user)
    @annotations ||= Annotation.for_image_with_user(id,user).where(:'users.active'=>true).order('annotations.created_at desc')
  end

  def is_favorite?(user)
    Gallery.get_favorites_list(user.id).saved_items.where(:druid=>id).size == 1
  end
  
  def edits
    @edits ||= ChangeLog.includes(:user).where(:druid=>id,:operation=>'metadata update').where(:'users.active'=>true).order('change_logs.created_at desc')
  end
  
  # Return a CollectionMembers object of all of the siblings of a collection member (including self)
  def siblings(params={})
    return nil unless is_item?

    rows=params[:rows] || blacklight_config.collection_member_grid_items
    start=params[:start] || 0
    random=params[:random] || false # if set to true, will give you a random selection from the collection ("start" will be ignored)
    include_hidden=params[:include_hidden] || false # if set to true, the query will also return hidden images
    
    if random
      start = self.total_siblings-rows < 0 ? 0 : rand(0...self.total_siblings-rows) # if we have less items than we want to show, just start at 0; else start at a random number between 0 and the total - # to show
    end
        
    fq="#{blacklight_config.collection_member_identifying_field}:\"#{self[blacklight_config.collection_member_identifying_field].first}\""
    fq+=" AND #{SolrDocument.images_query(:visible)}" unless include_hidden
    @siblings ||= CollectionMembers.new(
                               Blacklight.solr.select(
                                 :params => {
                                   :fq => fq,
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
    include_hidden=params[:include_hidden] || false # if set to true, the query will also return hidden images
    
    fq="#{blacklight_config.collection_member_identifying_field}:\"#{self[SolrDocument.unique_key]}\""
    fq+=" AND #{SolrDocument.images_query(:visible)}" unless include_hidden
    return CollectionMembers.new(
                              Blacklight.solr.select(
                                :params => {
                                  :fq => fq,
                                  :sort=> "priority_isi desc",
                                  :rows => rows.to_s,
                                  :start => start.to_s
                                }
                              )
                            )
  end  
  ###################
  
  def total_siblings(params={})
    self.collection.collection_members(params).total_members
  end
  
  def has_vehicle_metadata?
    return true if
      !self.current_owner.blank? || !self.marque.blank? || !self.vehicle_markings.blank? || !self.group_class.blank? || !self.model_year.blank?
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
    self.get_members(:rows=>1,:start=>0).first # never cache this so its always current
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

  # is item currently the top priority item in its collection?
  def top_priority?
    return false unless is_item?
    item_priority = self.priority
    collection_priority = self.collection.current_top_priority
    (item_priority == collection_priority) && item_priority != 0
  end

  # store the change log info into our local database before going to the ActiveSolr save method to perform the saves and editstore updates
  def save(params={})
    user=params[:user] || nil # currently logged in user, needed for some updates
    add_changelog(user)
    update_item # propoage unique information to database as well when saving solr document
    super
  end

  def add_changelog(user)
    ChangeLog.create(:druid=>id,:user_id=>user.id,:operation=>'metadata update',:note=>unsaved_edits.to_s) if (valid? && user)  
  end
  
  # propoage unique information to database as well when saving solr document
  def update_item
    @item=Item.find(id)
    @item.visibility_value=visibility_value
    @item.save
  end
  
   ##################################################################
   # CLASS LEVEL METHODS
   
   # specify solr fq queries for retrieving just visible, hidden or all images
   def self.images_query(visibility)
     case visibility
        when :visible
          "((*:* -visibility_isi:[* TO *]) OR visibility_isi:#{SolrDocument.visibility_mappings[:visible]})"
        when :hidden
          "(visibility_isi:#{SolrDocument.visibility_mappings[:hidden]})"
        when :preview
          "(visibility_isi:#{SolrDocument.visibility_mappings[:preview]})"
        else
          ''
      end
   end
   
   # Return an Array of all collection type SolrDocuments
   def self.all_collections(params={})
     highlighted=params[:highlighted] || false
     rows=params[:rows] || "10000"
     fq="#{self.config.collection_identifying_field}:\"#{self.config.collection_identifying_value}\""
     fq+=" AND highlighted_ssi:\"true\"" if highlighted
     Blacklight.solr.select(
       :params => {
         :fq => fq,
         :rows => rows,
         :sort=> "highlighted_ssi desc",
       }
     )["response"]["docs"].map do |document|
       SolrDocument.new(document)
     end
   end

   def self.highlighted_collections
     collections=self.all_collections(:highlighted=>true)
     collections.size > 0 ? collections : self.all_collections
   end
   
   # count the total number of images (default to those marked as visible only, can also pass in :all or :hidden)
  def self.total_images(visibility=:visible)
    params={:q=>'-format_ssim:collection',:fq=>self.images_query(visibility)}
    items=Blacklight.solr.get 'select',:params=>params      
    return items['response']['numFound']
  end
  
  def self.image_dimensions
    options = {:default => "_square",
               :large   => "_thumb" }
  end
  
  def self.bulk_update(params,user) # apply update to the supplied field with the supplied value to the specified list of druids; returns false if something didn't work
    
    selected_druids=params[:selected_druids]
    attribute=params[:attribute]
    new_value=params[:new_value]
  
    valid=false
    
    # iterate over all druids    
    selected_druids.each do |druid|
    
      doc=self.find(druid) # load solr doc
      if !doc.blank?
        doc.send("#{attribute}=",new_value) # this sets the attribute
        valid = doc.save(:user=>user) # if true, we have successfully updated solr
      end
      break unless valid # stop if any solr doc is not valid
      
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
