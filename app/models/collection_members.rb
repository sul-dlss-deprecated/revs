class CollectionMembers 
  include Enumerable
  attr_accessor :total_members, :documents

  def initialize(response)
    @total_members = response["response"]["numFound"]
    @documents = response["response"]["docs"].map{|d| SolrDocument.new(d) }
  end
  
  def each(&block)
    @documents.each(&block)
  end
  
  def size
    total_members
  end
  
  private
  
  # Send all calls to Enumerable public methods on to the documents array.
  def method_missing(method_name, *args, &block)
    if Enumerable.public_methods.include?(method_name)
      @documents.send(method_name, *args, &block)
    else
      super
    end
    
  end
  
end