class WithSolrDocument < ActiveRecord::Base
  self.abstract_class = true
  def solr_document
     @solr_document ||= SolrDocument.find(druid)
  end
end