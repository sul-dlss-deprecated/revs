# These methods are mixed into the SolrDocument model and provide ActiveRecord like finder by ID, dynamic setters and getters based on field configuration, and the ability to cache edits, update the solr document and more

module ActivesolrHelper

  attr_reader :errors
  
  module ClassMethods

     def find(id) # get a specific druid from solr and return a solrdocument class
       response = Blacklight.solr.select(
                                   :params => {
                                     :fq => "id:\"#{id}\"" }
                                 )
       docs=response["response"]["docs"].map{|d| self.new(d) }
       docs.size == 0 ? nil : docs.first
     end
     
     def multivalued_field_marker
       "_mvf" # you can end any set attribute that is a multivalued fields which should use a delimiter of the | character when editing into a single field
     end
     
     # ensures the input value is an array (just create a one element array if needed)
     def to_array(value)
       value.class == Array ? value : [value]
     end
     
     # tells you if have an blank value or an array that has just blank values
     def blank_value?(value)
        value.class == Array ? !value.delete_if(&:blank?).any? : value.blank? 
     end
     
     # attempts to determine if two values (i.e. old and new) are actually the same, by converting to arrays, and then ensuring everything is a string, and then comparing
     def is_equal?(old_values,new_values,multivalued_field=false)
       new_values_split = (multivalued_field && new_values.class != Array && !new_values.blank?) ? new_values.to_s.split("|") : new_values # if the user has indicated the first value is coming a special multivalued field entered as a single value, let's split along the delimiter
       compare_values1=self.to_array(old_values).collect{|val| val.to_s.strip}.delete_if(&:blank?).sort
       compare_values2=self.to_array(new_values_split).collect{|val| val.to_s.strip}.delete_if(&:blank?).sort
       compare_values1 == compare_values2
     end
     
  end
  
  # used to cache edits that can be saved later
  def unsaved_edits
    @unsaved_edits || {}
  end

  def cache_edit(new_entry)
    @unsaved_edits = {} if @unsaved_edits.nil?
    @unsaved_edits.merge!(new_entry)
    @dirty=true
  end
  
  # this method tells us if there are unsaved changes
  def dirty?
    @dirty || false
  end


  # you should redefine this method if you want to perform validations, if your method returns false, you should also set the @errors with a list of errors to display... setting false will NOT update solr
  def valid?
    
    true
    
  end

  # create the automatic getters/setters based on the configured fields
  def method_missing(meth,*args,&block)
  
    method = meth.to_s # convert method name to a string
    setter = method.end_with?('=') # determine if this is a setter method (which would have the last character "=" in the method name)
    attribute = setter ? method.chop : method # the attribute name needs to have the "=" removed if it is a setter
    multivalued_field = attribute.end_with?(self.class.multivalued_field_marker) # in place editing fields can end with the special character marker, which will join arrays when return; and split them when setting
    attribute.gsub!(self.class.multivalued_field_marker,'') if multivalued_field

    solr_field_config=self.class.field_mappings[attribute.downcase.to_sym]  # lookup the solr field for this accessor
    if solr_field_config
      solr_field_name=solr_field_config[:field].downcase
      default_value=solr_field_config[:default] || ''
      if setter # if it is a setter, cache the edit if it has changed
        old_values=self[solr_field_name]
        new_values=args.first
        if !self.class.is_equal?(old_values,new_values,multivalued_field) # we should only cache the edit if it actually changed
          value = (multivalued_field ? new_values.split("|") : new_values) # split the values when setting if this is an in place edit field
          cache_edit({solr_field_name.to_sym=>value})
          return value
        else
          return old_values
        end
      else # if it is a getter, return the value
        value = unsaved_edits[solr_field_name.to_sym] || self[solr_field_name]  # get the field value, either from unsaved edits or from solr document
        value = default_value if value.blank?
        return (multivalued_field && value.class == Array ? value.join(" | ") : value) # return a joined value if this is an in place edit field, otherwise just return the value
      end
    else
      super # we couldn't find any solr fields configured, so just send it to super
    end
  
  end

  # iterate through all cached unsaved edits and update solr
  def save
    
    if valid?
      
      unsaved_edits.each do |solr_field_name,value| 

        old_values=self[solr_field_name]   
        self.class.blank_value?(value) ? remove_field(solr_field_name) : set_field(solr_field_name,value) # update remote solr document
        self[solr_field_name]=value # update the local solr document
        
        # update Editstore database too if needed
        if self.class.use_editstore
                    
          if self.class.blank_value?(value) && !self.class.blank_value?(old_values) # the new value is blank, and the previous value exists, so send a delete operation
          
            send_delete_to_editstore(solr_field_name,'delete value')
          
          elsif !self.class.blank_value?(value) # there are some new values
            
            new_values=self.class.to_array(value) # ensure we have an array, even if its just one value - this makes the operations below more uniform
            
            if !self.class.blank_value?(old_values) # if a previous value(s) exist for this field, we either need to do an update (single valued), or delete all existing values (multivalued)
              if old_values.class == Array  # field is multivalued; delete all old values (this is because bulk does not pinpoint change values, it simply does a full replace of any multivalued field)    
                send_delete_to_editstore(solr_field_name,'delete all old values in multivalued field')
                send_creates_to_editstore(new_values,solr_field_name)
              elsif  # old value was single-valued, change operation
                send_update_to_editstore(new_values.first,old_values,solr_field_name)
              end
            else # no previous old values, so this must be an add
              send_creates_to_editstore(new_values,solr_field_name)
            end # end check for previous old values
            
          end # end check for new values being blank
          
        end # end send to editstore
      
      end # end loop over all unsaved changes
      
      @unsaved_edits={}
      @dirty=false
      return true
    
    else # end check for validity
    
      return false
    
    end
    
  end
  
  # updates the field in solr, editstore and in the object itself (useful in a callback method where you don't want to wait for saving or re-trigger callbacks)
  def immediate_update(field_name,new_value)
    send_update_to_editstore(new_value,self[field_name],field_name)
    update_solr(field_name,'set',new_value)
    self[field_name]=new_value
  end

  # removes the field in solr, editstore and in the object itself (useful in a callback method where you don't want to wait for saving or re-trigger callbacks)
  def immediate_remove(field_name)
    remove_field(field_name)
    send_delete_to_editstore(field_name)
    self[field_name]=nil
  end
  
  def send_update_to_editstore(new_value,old_value,solr_field_name,note='')
    Editstore::Change.create(:new_value=>new_value.to_s.strip,:old_value=>old_value,:operation=>:update,:state_id=>Editstore::State.ready.id,:field=>solr_field_name,:druid=>self.id,:client_note=>note)
  end
  
  def send_delete_to_editstore(solr_field_name,note='')
    Editstore::Change.create(:operation=>:delete,:new_value=>'',:state_id=>Editstore::State.ready.id,:field=>solr_field_name,:druid=>self.id,:client_note=>note)
  end
  
  def send_creates_to_editstore(new_values,solr_field_name,note='')
    new_values.each {|new_value| Editstore::Change.create(:new_value=>new_value.to_s.strip,:operation=>:create,:state_id=>Editstore::State.ready.id,:field=>solr_field_name,:druid=>self.id,:client_note=>note)}
  end
  
  # remove this field from solr
  def remove_field(field_name)
    update_solr(field_name,'remove',nil)
  end
  
  # add a new value to a multivalued field given a field name and a value
  def add_field(field_name,value)
    update_solr(field_name,'add',value)
    execute_callbacks(field_name,value)
  end
  
  # set the value for a single valued field or set all values for a multivalued field given a field name and either a single value or an array of values
  def set_field(field_name,value)
    values=self.class.to_array(value)
    update_solr(field_name,'set',values)
    execute_callbacks(field_name,values)
  end

  # update the value for a multivalued field from old value to new value (for a single value field, you can just set the new value directly)
  def update_field(field_name,old_value,new_value)
    if self[field_name].class == Array
      new_values=self[field_name].collect{|value| value.to_s==old_value.to_s ? new_value : value}
      update_solr(field_name,'set',new_values)
    else
      set_field(field_name,new_value)
    end
    execute_callbacks(field_name,value)
  end
  
  def execute_callbacks(field_name,value)
    callback_method=self.class.field_update_callbacks[field_name.to_sym]
    self.send(callback_method,field_name,value) unless callback_method.blank?
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
      new_values = new_values.map {|s| s.to_s.gsub("\\","\\\\\\").gsub('"','\"').strip} # strip leading/trailing spaces and escape quotes for each value
      params+="{\"set\":[\"#{new_values.join('","')}\"]}}]"      
    end
    RestClient.post url, params,:content_type => :json, :accept=>:json
  end
  
end
