module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
  def document_partial_name(document)
    case
      when document.collection?
        "collection"
      when document.collection_member?
        "collection_member"
      else
        "default"
    end
  end
end