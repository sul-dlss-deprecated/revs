class WithSolrDocument < ActiveRecord::Base
  self.abstract_class = true
  def solr_document
     @solr_document ||= SolrDocument.find(druid)
  end

  def update_source_id
    self.source_id = self.solr_document['source_id_ssi']
  end
  
  def update_item
    solr_document.update_item
  end
end