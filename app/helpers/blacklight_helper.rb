module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
  
  ###TODO:We may no longer need this override now that we are in blacklight 5+
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

end