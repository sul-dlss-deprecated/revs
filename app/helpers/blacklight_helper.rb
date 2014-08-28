module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
  
  ###TODO:We make no longer need this override now that we are in blacklight 5+
  def document_partial_name(document, base_name=nil)
    case
      when document.is_collection?
        "collection"
      when document.is_item?
        "collection_member"
      else
        "default"
    end
  end
  
  ### TODO: We can remove if we can use the bugfixed version of blacklight_range_limit (v2.2.0)
  def has_range_limit_parameters?(params = params)
     params[:range] && 
       params[:range].any? do |key, v| 
         v.present? && v.respond_to?(:'[]') && 
         (v["begin"].present? || v["end"].present? || v["missing"].present?)
       end
   end

   # over-ride, call super, but make sure our range limits count too
   def has_search_parameters?
     super || has_range_limit_parameters?
   end

   def query_has_constraints?(params = params)         
     super || has_range_limit_parameters?(params)
   end
   ##### end can remove

end