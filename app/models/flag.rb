class Flag < ActiveRecord::Base

  belongs_to :user
  
  FLAG_TYPES=%w{error inappropriate bookmark}
  
  FLAG_STATES={ open: 'open', fixed: 'fixed', wont_fix: 'wont fix'}  #add a potential spam state here if desired 
  
  attr_accessible :druid, :comment, :type, :flag_type, :user_id
  
  validates :druid, :is_druid=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :check_flag_type
  
  
  # head to solr to get the actual item, so we can access its attributes, like the title
  def item
    @item ||= SolrDocument.find(druid)
  end
  
  def check_flag_type
    errors.add(:flag_type, :not_valid) unless FLAG_TYPES.include? flag_type.to_s
  end
  
  def self.fixed
    return FLAG_STATES[:fixed]
  end
  
  def self.wont_fix
    return FLAG_STATES[:wont_fix]
  end
  
  def self.open
    return FLAG_STATES[:open]
  end
  
  def self.unresolved_count
    flags = Flag.all
    count = 0
    for f in flags
      if not f.resolved
        count += 1
      end 
    end
    return count
  end
  
  def resolved
    return (self.state == FLAG_STATES[:wont_fix] or self.state == FLAG_STATES[:fixed])
  end
  
 
  
end
