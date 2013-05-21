class Flag < ActiveRecord::Base

  belongs_to :user
  
  FLAG_TYPES=%w{error inappropriate bookmark}
  
  attr_accessible :druid, :comment, :type, :flag_type, :user_id
  
  validates :druid, :is_druid=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :check_flag_type
  
  # head to solr to get the actual item, so we can access its attributes, like the title
  def item
    @item ||= Item.find(druid)
  end
  
  def check_flag_type
    errors.add(:flag_type, "is not valid") unless FLAG_TYPES.include? flag_type.to_s
  end

  def is_cleared?
    !cleared.blank?
  end
  
end
