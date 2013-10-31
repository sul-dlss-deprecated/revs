class ChangeLog < ActiveRecord::Base

  attr_accessible :druid, :user_id, :operation, :note
  
  belongs_to :user

  validates :druid, :is_druid=>true
  validates :operation, :presence=>true
  validates :user_id, :numericality => { :only_integer => true }
  
  # head to solr to get the actual item, so we can access its attributes, like the title
  def item
    @item ||= SolrDocument.find(druid)
  end
  
  def updates
    eval(self.note)
  end
  
end
