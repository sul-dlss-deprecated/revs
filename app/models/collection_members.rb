class CollectionMembers 
  attr_accessor :total, :documents

  def initialize(response)
    @total = response["response"]["numFound"]
    @documents = response["response"]["docs"].map{|d| SolrDocument.new(d) }
  end
  
end