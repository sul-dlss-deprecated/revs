class Item < WithSolrDocument

 attr_accessible :druid,:visibility_value,:solr_document
    
 has_many :annotations, :foreign_key=>:druid, :primary_key=>:druid
 has_many :flags, :foreign_key=>:druid, :primary_key=>:druid
 
  validates :druid, :is_druid=>true
  validates :druid, :uniqueness=>true
  validate :check_visibility_value
  
  include VisibilityHelper  
    
  def check_visibility_value
    errors.add(:visibility_value, :not_valid) unless SolrDocument.visibility_mappings.values.include? visibility_value.to_s
  end
  
  # find by druid or create the row if it does not exist yet
  def self.fetch(druid)
    item=self.where(:druid=>druid).first
    return (item ? item : Item.create(:druid=>druid,:visibility_value=> SolrDocument.visibility_mappings[:visible]))
  end
   
end
