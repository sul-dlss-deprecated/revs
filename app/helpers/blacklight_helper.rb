module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
  def document_partial_name(document)
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