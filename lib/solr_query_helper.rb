module SolrQueryHelper

  def set_default_image_visibility_query
    if can? :view_hidden, SolrDocument
      self.blacklight_config.default_solr_params[:fq]=SolrDocument.images_query(:all) # if you can see hidden images, return all in queries
    else
      self.blacklight_config.default_solr_params[:fq]=SolrDocument.images_query(:visible) # if you cannot see hidden images, only return visible images
    end
  end

end