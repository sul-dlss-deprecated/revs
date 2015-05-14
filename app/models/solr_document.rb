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
  include Revs::Utils
        
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
      :description=>{:field=>'description_tsim', :multi_valued => true, :weight => 3},
      :photographer=>{:field=>'photographer_ssi', :weight => 1},
      :years=>{:field=>'pub_year_isim', :multi_valued => true, :weight => 5},
      :single_year=>{:field=>'pub_year_single_isi'},
      :full_date=>{:field=>'pub_date_ssi'},
      :people=>{:field=>'people_ssim', :multi_valued => true, :weight => 4},
      :subjects=>{:field=>'subjects_ssim', :multi_valued => true, :weight => 1},
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
      :vehicle_markings=>{:field=>'vehicle_markings_tsi', :weight => 1},
      :marque=>{:field=>'marque_ssim', :multi_valued => true, :weight => 4},
      :vehicle_model=>{:field=>'model_ssim', :multi_valued => true, :weight => 2},
      :model_year=>{:field=>'model_year_ssim', :multi_valued => true, :weight => 1},
      :current_owner=>{:field=>'current_owner_tsi', :weight => 1},
      :entrant=>{:field=>'entrant_ssim', :multi_valued => true, :weight => 1},
      :venue=>{:field=>'venue_ssi'},
      :track=>{:field=>'track_ssi', :weight => 1},
      :event=>{:field=>'event_ssi'},
      :group_class=>{:field=>'group_class_tsi', :weight => 1},
      :race_data=>{:field=>'race_data_tsi', :weight => 1},
      :priority=>{:field=>'priority_isi',:default=>0,:editstore=>false},
      :collections=>{:field=>'is_member_of_ssim', :multi_valued => true},
      :collection_names=>{:field=>'collection_ssim', :multi_valued => true,:editstore=>false},
      :archive_name=>{:field=>'archive_ssi',:editstore=>false},
      :highlighted=>{:field=>'highlighted_ssi',:editstore=>false},
      :visibility_value=>{:field=>'visibility_isi',:editstore=>false},
      :score=>{:field=>'score_isi', :editstore=>false},
      :timestamp=>{:field=>'timestamp', :editstore=>false}
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
  
  def druid
    id
  end

  # helper to determine if this is a revs_item, relies on the copyright statement
  def revs_item?
    copyright.downcase.include?('revs')
  end

  # some collections are not available for reproduction and will have their use and reproduction statement overriden on the website display to reduce re-use requests -- it can be done per collection
  # set the collections this applies for in config/application.rb
  def reproduction_not_available?
    !collections.blank? && !(collections & Revs::Application.config.collections_not_available_for_reproduction).blank?
  end
  
  def copyright
    value=self['copyright_ss']
    value = I18n.t('revs.contact.default_revs_copyright') if value.blank? # default value if not supplied
    return value
  end
  
  # revs items will be overridden in the view so we can add a link to the contact us page
  def use_and_reproduction
    if reproduction_not_available?
      value=I18n.t('revs.contact.image_not_available_for_reproduction')
    elsif self['use_and_reproduction_ss'].blank?
      value=I18n.t('revs.contact.default_revs_rights_statement')
    else
      value=self['use_and_reproduction_ss']    
    end
    return value
  end
  
  # a helper that makes it easy to show the document location as a single string
  def location
    [city_section,city,state,country].reject(&:blank?).join(', ')
  end

  def update_attribute(attribute,value)
     self.send("#{attribute}=",value) # this sets the given attribute
  end

  # we have a more complicated algorith, so will override the default scoring in activesolr helper
  def compute_score

    total_score=0
    total_weights=0
    self.class.field_mappings.each do |field_name,field_config|
      if !field_config[:weight].blank?
        total_score += field_config[:weight].to_f * (self.class.blank_value?(self.send(field_name)) ? 0 : 1) # if the field is blank, it is a 0 regardless of weight, otherwise it is a 1 times its weight
        total_weights += field_config[:weight].to_f
      end
    end

    # now we will account for the location, which has a weighting of 3 for *any* location like field having a value
    location_score = (location.blank? && venue.blank? && event.blank?) ? 0 : 1
    location_weight = 3
    total_weights += location_weight
    total_score += (location_score * location_weight)
    
    return ((total_score/total_weights)*100).ceil

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
      when :pub_date_ssi # if the user has updated a date field, we need to set the years appropriately but NOT send the year fields to editstore (since we only need the date field there)
        new_value=new_value.first if new_value.class == Array
        full_date=get_full_date(new_value)
        if full_date # if it's a valid full date, extract the year into the single and multi-valued year fields
          immediate_update('pub_year_single_isi',full_date.year.to_s,:ignore_editstore=>true)
          immediate_update('pub_year_isim',full_date.year.to_s,:ignore_editstore=>true) # but never send the year to editstore since the actual date is enough for the MODs
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
    
    unsaved_edits.dup.each do |solr_field_name,value| 

      case solr_field_name.to_sym
        when :model_year_ssim
          model_years=SolrDocument.to_array(value)
          @errors << 'Model years must be after 1850 up until this year and must be in the format YYYY'  if (!SolrDocument.blank_value?(model_years) && !model_years.all?{|new_value| is_valid_year?(new_value,1850)})
        when :pub_date_ssi
          @errors << 'Date must be in the format MM/DD/YYYY' if (!SolrDocument.blank_value?(value) && get_full_date(value) == false)
        when :pub_year_isim,:pub_year_single_isi
          self.years=RevsUtils.parse_years(SolrDocument.to_array(value).join('|'))
          if (!value.blank? && (SolrDocument.blank_value?(self.years) || !self.years.all?{|new_value| is_valid_year?(new_value,1800)}))
            @errors << 'A year must be after 1800 up until this year and must be in the format YYYY or XXXX-YYYY for a range of years' 
          end
        when :visibility_isi
          @errors << 'Visibility value not_valid' unless SolrDocument.visibility_mappings.values.include? value.to_s
      end
    
    end
    
    return @errors.size == 0

  end

  # use in the meta tag of the HTML, includes both title and description
  def meta_tag_description
    result=self.title 
    result += " : #{self.description}" unless self.description.blank?
    return result.gsub("\"","'")
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
                      Blacklight.default_index.connection.select(
                        :params => {
                          :fq => "#{SolrDocument.unique_key}:\"#{self[blacklight_config.collection_member_identifying_field].first}\""
                        }
                      )["response"]["docs"].first
                    )
  end
  #  
  ######################
  
  ######################
  # provides the equivalent of an ActiveRecord has_many relationship with flags, annotations, edits, images and siblings, and helper methods to determine if its a user favorite and which specific user galleries it is in
  def flags
    @flags ||= Flag.joins('left outer join users ON users.id = flags.user_id').where(:druid=>id).where("users.active='t' OR users.active='1' OR flags.user_id IS null").order('flags.created_at desc')
  end

  def saved_items
    @saved_items ||= SavedItem.includes(:gallery).where(:druid=>id).order('saved_items.created_at desc')
  end

  def annotations(user)
    @annotations ||= Annotation.for_image_with_user(id,user)
  end

  def is_favorite?(user)
    user.favorites.where(:druid=>id).size == 1
  end
  
  def in_galleries(user)
    Gallery.where(:"saved_items.druid"=>id,:user_id=>user,:gallery_type=>'user').includes(:all_saved_items)
  end

  def edits
    @edits ||= ChangeLog.joins(:user).where(:druid=>id,:operation=>'metadata update').where(:'users.active'=>true).order('change_logs.created_at desc')
  end
  
  # Return a CollectionMembers object of all of the siblings of a collection member (including self)
  def siblings(params={})
    return nil unless is_item?

    rows=params[:rows] || blacklight_config.collection_member_grid_items
    start=params[:start] || 0
    random=params[:random] || false # if set to true, will give you a random selection from the collection ("start" will be ignored)
    include_hidden=params[:include_hidden] || false # if set to true, the query will also return hidden images
    
    sort = (random ? "random_#{Random.new.rand(10000)} asc" : "priority_isi desc")
        
    fq="#{blacklight_config.collection_member_identifying_field}:\"#{self[blacklight_config.collection_member_identifying_field].first}\""
    fq+=" AND #{SolrDocument.images_query(:visible)}" unless include_hidden
    @siblings ||= CollectionMembers.new(
                               Blacklight.default_index.connection.select(
                                 :params => {
                                   :fq => fq,
                                   :sort=> sort,
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
    random=params[:random] || false

    sort = (random ? "random_#{Random.new.rand(10000)} asc" : "priority_isi desc")
    fq="#{blacklight_config.collection_member_identifying_field}:\"#{self[SolrDocument.unique_key]}\""
    fq+=" AND #{SolrDocument.images_query(:visible)}" unless include_hidden
    return CollectionMembers.new(
                              Blacklight.default_index.connection.select(
                                :params => {
                                  :fq => fq,
                                  :sort=> sort,
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
      !self.current_owner.blank? || !self.vehicle_model.blank? || !self.marque.blank? || !self.vehicle_markings.blank? || !self.group_class.blank? || !self.model_year.blank?
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
  
  def first_item(params={})
    return nil unless is_collection?
    self.get_members({:rows=>1,:start=>0}.merge(params)).first # never cache this so its always current
  end
  
  # tells you if there are any visible items in the collection (for the special case where all of the items in a collection have been hidden)
  def visible_items_in_collection?
    !first_item.nil?
  end
  
  # gives you the representative image of the collection
  def first_image(params={})
    return nil unless is_collection?
    first_item(params).nil? ? nil : first_item(params).images(:large).first
  end

  # gives you a random item from the given collection
  def random_item
    return nil unless is_collection?
    self.get_members(:rows=>1,:start=>(Random.new.rand(self.get_members.size-1))).first
  end

  # gives you the current top priority number for item sorting for the given collection
  def current_top_priority
    return nil unless is_collection?
    first_item(:include_hidden=>true).priority.to_i
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

  # override the general save method from activesolr helper so we can do some revs specific stuff first
  # store the change log info into our local database before going to the ActiveSolr save method to perform the saves and editstore updates
  def save(params={})
    user=params[:user] || nil # currently logged in user, needed for some updates
    add_changelog(user)
    self.score = compute_score
    self.archive_name = Revs::Application.config.collier_archive_name if self.archive_name.blank?
    update_item # propogate unique information to database as well when saving solr document
    super
  end

  def add_changelog(user)
    if (valid? && dirty? && user)  
      changelog=ChangeLog.new
      changelog.druid=id
      changelog.user_id=user.id
      changelog.operation='metadata update'
      changelog.note=unsaved_edits.to_s
      changelog.save
      changelog
    end
  end
  
  # propogate unique information and cache title to database as well when saving solr document
  def update_item
    item=Item.find(id)
    item.title=title[0..399]
    item.visibility_value=(visibility_value.blank? ? SolrDocument.visibility_mappings[:visible] : visibility_value) 
    item.save
    item
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
     fq+=self.images_query(:visible) # only show collections marked as visible
     if highlighted
       default_sort="highlighted_dti desc"     
       fq+=" AND highlighted_ssi:\"true\"" 
     else
       default_sort="title_tsi asc"
     end
     sort=params[:sort] || default_sort
     
     Blacklight.default_index.connection.select(
       :params => {
         :fq => fq,
         :rows => rows,
         :sort=> sort,
       }
     )["response"]["docs"].map do |document|
       SolrDocument.new(document)
     end
   end

   def self.highlighted_collections
     collections=self.all_collections(:highlighted=>true)
     collections.size > 0 ? collections : self.all_collections # if there are highlighted collections, show them, else show them all
   end
   
   # count the total number of images (default to those marked as visible only, can also pass in :all or :hidden)
  def self.total_images(visibility=:visible)
    params={:q=>'-format_ssim:collection',:fq=>self.images_query(visibility)}
    items=Blacklight.default_index.connection.get 'select',:params=>params      
    return items['response']['numFound']
  end
  
  def self.image_dimensions
    options = {:default => "_square",
               :large   => "_thumb" }
  end
  
  def self.bulk_update(params,user) # apply update to the supplied field with the supplied value to the specified list of druids; returns false if something didn't work
    
    selected_druids=params[:selected_druids]
    attribute=params[:attribute]
    search_value=params[:search_value]
    new_value=params[:new_value]
    action=params[:action]
  
    valid=false
    
    # iterate over all druids    
    selected_druids.each do |druid|
    
      doc=self.find(druid) # load solr doc
      if !doc.blank?
        case action 
          when 'remove' # completely remove existing value
            doc.update_attribute(attribute,'') # this sets the attribute to blank
          when 'update' # completely replace the old value with the new value
            doc.update_attribute(attribute,new_value) # this sets the attribute
          when 'replace' # only replace the old value if it matches the search value exactly (and only one value needs to match in an MVF field)
            if attribute.end_with? SolrDocument.multivalued_field_marker #  attribute being operated on is a multivalued field
              attribute_name_without_mvf=attribute.chomp(SolrDocument.multivalued_field_marker)
              current_values=doc.send("#{attribute}") # current values as a delimited string
              current_values_array=doc.send("#{attribute_name_without_mvf}") # current values as an array
              if !current_values_array.empty? # we have multiple values
                new_values_array = current_values_array.map {|value| value.gsub(search_value.strip,new_value.strip) }# iterate through existing values and replace with new value
                doc.update_attribute(attribute_name_without_mvf,new_values_array)
              end
            else # attribute being operated on is a single valued field
              value=doc.send("#{attribute}")
              doc.update_attribute(attribute,value.gsub(search_value.strip,new_value.strip)) if (!value.blank? && value.include?(search_value.strip)) # replace with the new value if search string exists
            end
          end
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
