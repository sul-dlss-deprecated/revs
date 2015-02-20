class WithSolrDocument < ActiveRecord::Base
  self.abstract_class = true
  def solr_document
     @solr_document ||= SolrDocument.find(druid)
  end

  def update_item
    solr_document.update_item
  end
end