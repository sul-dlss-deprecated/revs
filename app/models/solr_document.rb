# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document
  extend DateHelpers
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
                             
  # these are all date fields, and updating any of them will trigger some automatic computations and settings for the others
  DATE_FIELDS=[:pub_date_ssi,:pub_year_isim,:pub_year_single_isi]
  
  # a hash of attribute names to solr document field names, used by method missing
  # attributes in lowercase symbols; set to a hash with :field denothing the solr field name, and the optional :default denoting the value to set if solr field is blank
  FIELD_MAPPINGS={
    :title=>{:field=>'title_tsi',:default=>'Untitled'},
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
  
  IN_PLACE_EDIT_FIELD = "_ipe" # in place edit fields end with this 
  
  self.unique_key = 'id'

  # this exposes the field mappings, which can be useful in the UI
  def self.field_mappings
    FIELD_MAPPINGS
  end
  
  def method_missing(meth,*args,&block)
    
    method = meth.to_s # convert method name to a string
    setter = method.end_with?('=') # determine if this is a setter method (which would have the last character "=" in the method name)
    attribute = setter ? method.chop : method # the attribute name needs to have the "=" removed if it is a setter
    in_place_edit_field = attribute.end_with?(IN_PLACE_EDIT_FIELD) # in place editing fields can end with _ipe, which will join arrays when return; and split them when setting
    attribute.gsub!(IN_PLACE_EDIT_FIELD,'') if in_place_edit_field
    
    solr_field_config=FIELD_MAPPINGS[attribute.downcase.to_sym]  # lookup the solr field for this accessor
    if solr_field_config
      solr_field_name=solr_field_config[:field].downcase
      default_value=solr_field_config[:default] || ''
      if setter # if it is a setter, set the appropriate field in solr
        value = (in_place_edit_field ? args.first.split("|") : args.first) # split the values when setting if this is an in place edit field
        set_field(solr_field_name,value)
        return value
      else # if it is a getter, return the value
        value = self[solr_field_name]  # get the field value
        value = default_value if value.blank?
        return (in_place_edit_field && value.class == Array ? value.join(" | ") : value) # return a joinde value if this is an in place edit field, otherwise just return the value
      end
    else
      super # we couldn't find any solr fields configured, so just send it to super
    end
    
  end
  
  def flags
    Flag.includes(:user).where(:druid=>id)
  end

  def annotations(user)
    Annotation.for_image_with_user(id,user)
  end

  # we need a custom getter/setter for the description field because
  # for some reason, we have description as a multivalued field, but we really only need it to be a single valued field
  def description 
    desc=self['description_tsim']
    desc.class == Array ? desc.first : desc
  end
  def description=(value)
    set_field('description_tsim',value.strip)
  end
  
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

  # Return a CollectionMembers object of just the members of a collection, and cache the result in the object so we can use on the page over again
  def collection_members(params={})
    return nil unless is_collection?
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
    set_field('priority_isi',collection.current_top_priority + 1)
    return true
  end
  
  # Return a CollectionMembers object of all of the siblings of a collection member (including self)
  def collection_siblings(params={})
    return nil unless is_item?

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

  def images(size=:default)
    return nil unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Revs::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      "#{stacks_url}/#{self["id"]}/#{image_id}#{SolrDocument.image_dimensions[size]}"
    end
  end

  # remove this field from solr
  def remove_field(field_name)
    update_solr(field_name,'remove',nil)
  end
  
  # add a new value to a multivalued field given a field name and a value
  def add_field(field_name,value)
    update_solr(field_name,'add',value)
    update_date_fields(field_name,value) if DATE_FIELDS.include? field_name.to_sym
  end
  
  # set the value for a single valued field or set all values for a multivalued field given a field name and either a single value or an array of values
  def set_field(field_name,value)
    value=[value] unless value.class == Array # turn the value into an array if its not one, this will enable the query below to work for both single values and arrays
    update_solr(field_name,'set',value)
    update_date_fields(field_name,value) if DATE_FIELDS.include? field_name.to_sym
  end

  # update the value for a multivalued field from old value to new value (for a single value field, you can just set the new value directly)
  def update_field(field_name,old_value,new_value)
    if self[field_name].class == Array
      new_values=self[field_name].collect{|value| value.to_s==old_value.to_s ? new_value : value}
      update_solr(field_name,'set',new_values)
    else
      set_field(field_name,new_value)
    end
    update_date_fields(field_name,value) if DATE_FIELDS.include? field_name.to_sym
  end
  
  def update_solr(field_name,operation,new_values)
    url="#{Blacklight.solr.options[:url]}/update?commit=true"
    params="[{\"id\":\"#{id}\",\"#{field_name}\":"
    if operation == 'add'
      params+="{\"add\":\"#{new_values.gsub('"','\"')}\"}}]"
    elsif operation == 'remove'
      params+="{\"set\":null}}]"          
    else
      new_values=[new_values] unless new_values.class==Array
      new_values = new_values.map {|s| s.to_s.gsub('"','\"').strip} # strip leading/trailing spaces and escape quotes for each value
      params+="{\"set\":[\"#{new_values.join('","')}\"]}}]"      
    end
    RestClient.post url, params,:content_type => :json, :accept=>:json
  end
  
  # if the user updates one of the date fields, we'll run some computations to update the others as needed
  def update_date_fields(field_name,new_value)
    case field_name.to_sym
      when :pub_year_isim, :pub_year_single_isi # if the user has updated a year field, we need to blank out the date, since its no longer valid
        remove_field('pub_date_ssi')
      when :pub_date_ssi # if the user has updated a date field, we need to set the years appropriately
        new_value=new_value.first if new_value.class == Array
        full_date=get_full_date(new_value)
        if full_date # if it's a valid full date, extract the year into the single and multi-valued year fields
          update_solr('pub_year_isim','set',full_date.year.to_s)
          update_solr('pub_year_single_isi','set',full_date.year.to_s)
        else # if it's not a valid date, clear the year fields
          remove_field('pub_year_isim')
          remove_field('pub_date_single_isi')
        end
    end    
  end
  
  # CLASS LEVEL METHODS
   # Return an Array of collection SolrDocuments
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
 
  def self.find(id) # get a specific druid from solr and return a solrdocument class
    response = Blacklight.solr.select(
                                :params => {
                                  :fq => "id:\"#{id}\"" }
                              )
    docs=response["response"]["docs"].map{|d| self.new(d) }
    docs.size == 0 ? nil : docs.first
  end

  def self.bulk_update(params) # apply update to the supplied field with the supplied value to the specified list of druids
    
    selected_druids=params[:selected_druids]
    field_name=params[:field_name]
    new_value=params[:new_value]
        
     # pipes can be used to denote multiple values in a multivalued field (except description, which should just be single valued!)
    if (field_name[-1,1].downcase=='m' && field_name.to_sym != 'description_tsim')
      new_values=new_value.split("|") 
    else
      new_values=[new_value]
      
    end
    # perform some validation of fields
    case field_name.to_sym
      when :pub_date_ssi
        valid = new_values.all? {|new_value| self.get_full_date(new_value)}
      when :pub_year_isim,:pub_year_single_isi
        valid = new_values.all? {|new_value| self.is_valid_year?(new_value)}
      else
        valid=true
    end
    
    if valid # entered values were valid
    
      selected_druids.each do |druid|
      
        item=self.find(druid)
        old_values=item[field_name]
      
        if !old_values.nil? # if a previous value(s) exist for this field, we either need to do an update (single valued), or delete all existing values (multivalued)
          if old_values.class == Array  # multivalued; delete all old values (this is because bulk does not pinpoint change values, it simply does a full replace of any multivalued field)    
            Editstore::Change.create(:operation=>:delete,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid,:client_note=>'delete all old values in multivalued field')
          else # single-valued, change operation 
            Editstore::Change.create(:new_value=>new_values.first.strip,:old_value=>old_values.strip,:operation=>:update,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)
          end
        end
      
        if old_values.nil? || old_values.class == Array # if previous value didn't exist or we are updating a multvalued field, let's create the new values
          new_values.each {|new_value| Editstore::Change.create(:new_value=>new_value.strip,:operation=>:create,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)} # add all new values to DOR        
        end
      
        item.set_field(field_name,new_values) # update solr
      
      end

      return true
      
    else # something was invalid
      
      return false
    
    end
    
  end
  
  # used to build the drop down menu of available fields for bulk updating -- add the text to be shown to user and the field in solr doc and Editstore fields table
  def self.bulk_update_fields
    [
      ['Title','title_tsi'],
      ['Formats','format_ssim'],
      ['Years','pub_year_isim'],
      ['Date','pub_date_ssi'],
      ['Description','description_tsim'],
      ['Marques','marque_ssim'],
      ['Models','model_ssim'],
      ['Model Years','model_year_ssim'],
      ['People','people_ssim'],
      ['Entrant','entrant_ssi'],
      ['Current Owner','current_owner_ssi'],
      ['Venue','venue_ssi'],
      ['Track','track_ssi'],
      ['Event','event_ssi'],
      ['Location','location_ssi'],
      ['Group/Class','group_class_tsi'],
      ['Race Data','race_data_tsi'],
      ['Photographer','photographer_ssi']
    ]
  end

  private
  def self.config
    CatalogController.blacklight_config  
  end
  
  def blacklight_config
    self.class.config
  end
  
end
