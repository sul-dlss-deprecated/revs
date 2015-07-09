# These methods are mixed into the SolrDocument model and provide ActiveRecord like finder by ID, dynamic setters and getters based on field configuration, and the ability to cache edits, update the solr document and more

module ActivesolrHelper

  attr_reader :errors
  
  module ClassMethods
    
     def find(id) # get a specific druid from solr and return a solrdocument class
       response = Blacklight.default_index.connection.select(
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
     
     # tells you if have a blank value or an array that has just blank values
     def blank_value?(value)
        value.class == Array ? !value.delete_if(&:blank?).any? : value.blank? 
     end
     
     # attempts to determine if two values (i.e. old and new) are actually the same, by converting to arrays, and then ensuring everything is a string, and then comparing
     def is_equal?(old_values,new_values,multivalued_field=false)
       new_values_split = (multivalued_field && new_values.class != Array && !new_values.blank?) ? new_values.to_s.split("|") : new_values # if the user has indicated the first value is coming a special multivalued field entered as a single value, let's split along the delimiter
       compare_values1=self.to_array(old_values).collect{|val| val.to_s.strip.gsub(/\r\n?/, "\n")}.delete_if(&:blank?).sort
       compare_values2=self.to_array(new_values_split).collect{|val| val.to_s.strip.gsub(/\r\n?/, "\n")}.delete_if(&:blank?).sort
       compare_values1 == compare_values2
      end
     
  end
  
  # used to computed a weight "score" for the document, based on how you weight each field; helps identify how "filled in" a document is for metadata purposes
  # final result is a value between 0 (nothing) and 100 (all filled in)
  # if you have a more complicated algorithm, you can override this method in solr_document.rb
  def compute_score
    
    total_score=0
    total_weights=0
    self.class.field_mappings.each do |field_name,field_config| 
      if !field_config[:weight].blank?
        total_score += field_config[:weight].to_f * (self.class.blank_value?(self.send(field_name)) ? 0 : 1) # if the field is blank, it is a 0 regardless of weight, otherwise it is a 1 times its weight
        total_weights += field_config[:weight].to_f
      end
    end
    
    return ((total_score/total_weights)*100).ceil
    
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


  # you should redefine this method in your own model class if you want to perform validations, if your method returns false, you should also set the @errors with a list of errors to display... setting false will NOT update solr
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
  def save(params={})
    
    user=params[:user] || nil # currently logged in user, needed for some updates
    commit=params[:commit].nil? ? true : params[:commit] # if solr document should be committed immediately, defaults to true
    
    if valid?

      updates_for_solr=[] # an array of hashes for the solr updates we will post to solr
      
      unsaved_edits.each do |solr_field_name,value| 

        old_values=self[solr_field_name]   
        
        if self.class.blank_value?(value) 
          execute_callbacks(solr_field_name,nil)
          updates_for_solr << {:field=>solr_field_name,:operation=>'remove'}
        else
          execute_callbacks(solr_field_name,self.class.to_array(value))
          updates_for_solr << {:field=>solr_field_name,:operation=>'set',:new_values=>value}
        end
        
        self[solr_field_name]=value # update in memory solr document so value is available without reloading solr doc from server
        
        # get the solr field configuration for this field
        solr_field_config=self.class.field_mappings.collect{|key,value| value if value[:field]==solr_field_name.to_s}.reject(&:blank?).first
                
        # update Editstore database too if needed
        if self.class.use_editstore && (solr_field_config[:editstore].nil? || solr_field_config[:editstore] == true)
                    
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
      
      # send updates to solr
      batch_update(updates_for_solr,commit) if updates_for_solr.size > 0 # check to be sure we actually have some updates to apply
      
      @unsaved_edits={}
      @dirty=false
      return true
    
    else # end check for validity
    
      return false
    
    end
    
  end
  
  # updates the field in solr, editstore and in the object itself (useful in a callback method where you don't want to wait for saving or re-trigger callbacks)
  def immediate_update(field_name,new_value,params={})
    ignore_editstore=params[:ignore_editstore] || false
    if self.class.blank_value?(new_value)
      immediate_remove(field_name)
    else
      update_solr(field_name,'set',new_value)
      send_update_to_editstore(new_value,self[field_name],field_name) if (self.class.use_editstore && !ignore_editstore)
      self[field_name]=new_value
    end
  end

  # removes the field in solr, editstore and in the object itself (useful in a callback method where you don't want to wait for saving or re-trigger callbacks)
  def immediate_remove(field_name,params={})
    ignore_editstore=params[:ignore_editstore] || false
    update_solr(field_name,'remove',nil)
    send_delete_to_editstore(field_name) if (self.class.use_editstore && !ignore_editstore)
    self[field_name]=nil
  end
  
  def send_update_to_editstore(new_value,old_value,solr_field_name,note='')    
    old_value = (old_value.class == Array ? old_value.join(',') : old_value)
    change=Editstore::Change.new
    change.new_value=new_value.to_s.strip
    change.old_value=old_value
    change.operation=:update
    change.state_id=Editstore::State.ready.id
    change.field=solr_field_name
    change.druid=self.id
    change.client_note=note
    change.save
  end
  
  def send_delete_to_editstore(solr_field_name,note='')
    change=Editstore::Change.new
    change.new_value=''
    change.operation=:delete
    change.state_id=Editstore::State.ready.id
    change.field=solr_field_name
    change.druid=self.id
    change.client_note=note
    change.save
  end
  
  def send_creates_to_editstore(new_values,solr_field_name,note='')
    new_values.each do |new_value|
      change=Editstore::Change.new
      change.new_value=new_value.to_s.strip
      change.operation=:create
      change.state_id=Editstore::State.ready.id
      change.field=solr_field_name
      change.druid=self.id
      change.client_note=note
      change.save      
    end 
  end
  
  # remove this field from solr
  def remove_field(field_name,commit=true)
    update_solr(field_name,'remove',nil,commit)
    execute_callbacks(field_name,nil)
  end
  
  # add a new value to a multivalued field given a field name and a value
  def add_field(field_name,value,commit=true)
    update_solr(field_name,'add',value,commit)
    execute_callbacks(field_name,value)
  end
  
  # set the value for a single valued field or set all values for a multivalued field given a field name and either a single value or an array of values
  def set_field(field_name,value,commit=true)
    values=self.class.to_array(value)
    update_solr(field_name,'set',values,commit)
    execute_callbacks(field_name,values)
  end

  # update the value for a multivalued field from old value to new value (for a single value field, you can just set the new value directly)
  def update_field(field_name,old_value,new_value,commit=true)
    if self[field_name].class == Array
      new_values=self[field_name].collect{|value| value.to_s==old_value.to_s ? new_value : value}
      update_solr(field_name,'set',new_values,commit)
    else
      set_field(field_name,new_value,commit)
    end
    execute_callbacks(field_name,value)
  end
  
  def execute_callbacks(field_name,value)
    callback_method=self.class.field_update_callbacks[field_name.to_sym]
    self.send(callback_method,field_name,value) unless callback_method.blank?
  end
  
  # run a bunch of updates to a series of fields all at once, like on save, so that we can update an entire object with one solr call
  def batch_update(updates,commit=true)
    params="[{\"id\":\"#{id}\","
    updates.each do |update|
      params+="\"#{update[:field]}\":"
      if update[:operation] == 'add'
        params+="{\"add\":\"#{update[:new_values].gsub('"','\"')}\"}"
      elsif update[:operation] == 'remove'
        params+="{\"set\":null}"          
      else
        update[:new_values]=self.class.to_array(update[:new_values])
        new_values = update[:new_values].map {|s| s.to_s.gsub("\\","\\\\\\").gsub('"','\"').strip} # strip leading/trailing spaces and escape quotes for each value
        params+="{\"set\":[\"#{new_values.join('","')}\"]}"      
      end
      params+=","
    end    
    params.chomp!(",")
    params+="}]"
    post_to_solr(params,commit)
  end
  
  # run a single field update/delete to a solr record
  def update_solr(field_name,operation,new_values,commit=true)
    params="[{\"id\":\"#{id}\",\"#{field_name}\":"
    if operation == 'add'
      params+="{\"add\":\"#{new_values.gsub('"','\"')}\"}}]"
    elsif operation == 'remove'
      params+="{\"set\":null}}]"          
    else
      new_values=self.class.to_array(new_values)
      new_values = new_values.map {|s| s.to_s.gsub("\\","\\\\\\").gsub('"','\"').strip} # strip leading/trailing spaces and escape quotes for each value
      params+="{\"set\":[\"#{new_values.join('","')}\"]}}]"      
    end
    post_to_solr(params,commit)
  end

  # just send a hard commit to solr
  def send_commit
    post_to_solr({},true)
  end

  # make a post to solr with the supplied params, and optionally hard commit
  def post_to_solr(params,commit=true)
    url="#{Blacklight.default_index.connection.options[:url]}/update?commit=#{commit}"
    RestClient.post url, params,:content_type => :json, :accept=>:json
  end
    
end
