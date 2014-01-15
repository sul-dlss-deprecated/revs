class Flag < WithSolrDocument

  belongs_to :user
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
  
  FLAG_TYPES=%w{error inappropriate}
  
  FLAG_STATES={ open: 'open', fixed: 'fixed', wont_fix: 'wont fix'}  #add a potential spam state here if desired 
  FLAG_STATE_DISPLAYS = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_diplay_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name'),FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_closed_name'),FLAG_STATES[:open]+","+FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_flags_name')}
  
  attr_accessible :druid, :comment, :flag_type, :user_id, FLAG_TYPES
  
  validates :druid, :is_druid=>true
  validates :user_id, :numericality => { :only_integer => true }
  validate :check_flag_type
  
  FLAGS_PER_TABLE_PAGE = 25
  
  def check_flag_type
    errors.add(:flag_type, :not_valid) unless FLAG_TYPES.include? flag_type.to_s
  end
  
  def self.per_table_page
    return FLAGS_PER_TABLE_PAGE
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

  # get total flag unresolved count, or for a specific druid if you pass it in
  def self.unresolved_count(druid=nil)
    counts=Flag.where(:state=>'open')
    counts=counts.where(:druid=>druid) if druid
    counts.size
  end
  
  def resolved
    return (self.state == FLAG_STATES[:wont_fix] or self.state == FLAG_STATES[:fixed])
  end
  
  def state_display_name
    return FLAG_STATE_DISPLAYS[self.state]
  end
  
  def self.display_resolved_columns(options)
    return (options.include? Flag.fixed or options.include? Flag.wont_fix)
  end
  
  def self.groupByFlagState
    return Flag.group("druid", "state").size
  end
  
  def self.queryFlagGroup(flag_group, druid, state)
    return flag_group[[druid,state]] || 0
  end
  
 
  
end
