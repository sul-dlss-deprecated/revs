class CollectionHighlight < ActiveRecord::Base
  attr_accessible :druid, :image_id,:image_url,:sort_order

  def self.all_in_solr
    
    # get the collection highlights from the database
    highlights = self.all
    
    highlight_collections_query=Blacklight.solr.get 'select',:params=>{:q=>highlights.map{|highlight| 'id:"' + highlight.druid + '"'}.join(' OR ')} # now to go solr to get the documents, since we only want highlights that are in solr
    highlight_collections=highlight_collections_query['response']['docs'].shuffle # this randomizes it
    highlight_collections.each {|highlight| highlight.merge!('image_url'=>self.find_by_druid(highlight['id']).image_url)} # add the URL for each highlight image to the solr documents
    
    return highlight_collections.map {|highlight| SolrDocument.new(highlight)}
    
  end

end
