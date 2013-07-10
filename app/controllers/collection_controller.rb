class CollectionController < ApplicationController

  def index
    collections_solr=Blacklight.solr.get 'select',:params=>{:q=>'format_ssim:collection'}
    @collections=collections_solr['response']['docs'].collect{|doc| SolrDocument.new(doc)}
  end

end
