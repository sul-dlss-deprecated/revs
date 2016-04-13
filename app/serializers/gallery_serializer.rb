# this is used to serialize a gallery object to JSON for an API call (for the gallery#show method)

class GallerySerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :saved_items_count, :gallery_type, :created_by, :images, :items, :item_ids, :created_at

  # only return this many items in the API to avoid overload
  def item_limit
    100
  end

  def created_by
    object.user.to_s
  end

  def images
    object.saved_items.limit(item_limit).collect { |item| item.solr_document.images(:large).first }
  end

  def items
    object.saved_items.limit(item_limit).collect { |item| item.druid }
  end

  def item_ids
    object.saved_items.limit(item_limit).collect { |item| item.solr_document.identifier }
  end

end
