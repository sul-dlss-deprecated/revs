class Flag < ActiveRecord::Base

  belongs_to :user
  
  FLAG_TYPES=%w{error inappropriate bookmark}
  
  FLAG_STATES={ open: 'open', fixed: 'fixed', wont_fix: 'wont fix'}  #add a potential spam state here if desired 
  FLAG_STATE_DISPLAYS = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_diplay_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name'),FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_closed_name'),FLAG_STATES[:open]+","+FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_flags_name')}
  
  attr_accessible :druid, :comment, :type, :flag_type, :user_id, FLAG_TYPES
  
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
  
  def self.for_dropdown
    return FLAG_STATE_DISPLAYS
  end

  def self.unresolved_count
    Flag.where(:state=>'open').count
  end
  
  def resolved
    return (self.state == FLAG_STATES[:wont_fix] or self.state == FLAG_STATES[:fixed])
  end
  
  def unresolved_for_druid
  
  end
  
  def state_display_name
    return FLAG_STATE_DISPLAYS[self.state]
  end
  
  def self.display_resolved_columns(options)
    return (options.include? Flag.fixed or options.include? Flag.wont_fix)
  end
  
 
  
end
