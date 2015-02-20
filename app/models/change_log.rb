class ChangeLog < WithSolrDocument
  
  belongs_to :user
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
  after_save :update_item

  validates :druid, :is_druid=>true
  validates :operation, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  
  def updates
    eval(self.note)
  end
  
end
