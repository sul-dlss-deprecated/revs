class Item < WithSolrDocument
    
 has_many :annotations, :foreign_key=>:druid, :primary_key=>:druid
 has_many :flags, :foreign_key=>:druid, :primary_key=>:druid
 has_many :saved_items, :foreign_key=>:druid, :primary_key=>:druid
 has_many :change_logs, :foreign_key=>:druid, :primary_key=>:druid
 
  before_create :update_source_id
  validates :druid, :is_druid=>true
  validates :druid, :uniqueness=>true
  validate :check_visibility_value
  
  include VisibilityHelper  
    
  def check_visibility_value
    errors.add(:visibility_value, :not_valid) unless SolrDocument.visibility_mappings.values.include? visibility_value.to_s
  end
  
  # find by druid or create the row if it does not exist yet
  def self.find(druid)
    item=self.where(:druid=>druid).first
    return (item ? item : Item.create_new(:druid=>druid,:visibility_value=>SolrDocument.visibility_mappings[:visible]))
  end
  
  def self.create_new(params)
    item=Item.new
    item.druid=params[:druid]
    item.visibility_value=params[:visibility_value]
    item.save
    item
  end
   
end
