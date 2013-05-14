class Flag < ActiveRecord::Base

  belongs_to :user
  
  FLAG_TYPES=%w{error inappropriate}
  
  attr_accessible :druid, :comment, :type
  
  validates :druid, :is_druid=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :check_flag_type
  
  def check_flag_type
    errors.add(:flag_type, "is not valid") unless FLAG_TYPES.include? flag_type.to_s
  end

  def is_cleared?
    !cleared.blank?
  end
  
end
