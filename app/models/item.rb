class Item

  # A nify little helper class to grab you a Solr Document given an ID.  Helpful on the console:
  # doc = Item.find('qb957rw1430')
  # puts doc.title

  def self.find(id)
    response = Blacklight.solr.select(
                                :params => {
                                  :fq => "id:\"#{id}\"" }
                              )
    docs=response["response"]["docs"].map{|d| SolrDocument.new(d) }
    docs.size == 0 ? nil : docs.first
  end
    
end
