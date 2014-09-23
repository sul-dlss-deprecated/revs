class Flag < WithSolrDocument

  belongs_to :user
  belongs_to :resolved_by, :class_name=>'User', :foreign_key=>:resolving_user
  belongs_to :item, :foreign_key=>:druid, :primary_key=>:druid
  
  FLAG_TYPES=%w{error inappropriate}
  NOTIFICATION_STATES=%w{pending delivered}
    
  FLAG_STATES={ open: 'open', fixed: 'fixed', wont_fix: 'wont fix'}  #add a potential spam state here if desired 
  FLAG_STATE_DISPLAYS = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_diplay_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name'),FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_closed_name'),FLAG_STATES[:open]+","+FLAG_STATES[:wont_fix]+","+FLAG_STATES[:fixed]=>I18n.t('revs.flags.all_flags_name')}
  
  validates :druid, :is_druid=>true
  validate :check_user_id
  validate :check_flag_type
  validate :check_flag_state
  validate :check_notification_state

  def self.create_new(flag_info,user)
    flag=Flag.new
    flag.flag_type=flag_info[:flag_type]
    flag.comment=flag_info[:comment]
    flag.druid=flag_info[:druid]
    flag.notification_state="pending" if flag_info[:notify_me] == '1'
    flag.user_id=user.id unless user.blank?
    flag.state= Flag.open
    flag.private_comment=flag_info[:private_comment]
    flag.save 
    flag 
  end

  def self.fixed
    return FLAG_STATES[:fixed]
  end
  
  def self.wont_fix
    return FLAG_STATES[:wont_fix]
  end

  def self.closed
    [FLAG_STATES[:wont_fix],FLAG_STATES[:fixed]]
  end
  
  def self.open
    return FLAG_STATES[:open]
  end
  
  def self.for_dropdown
    return FLAG_STATE_DISPLAYS
  end

  def self.display_resolved_columns(options)
    self.closed.map {|closed_state| options.include? closed_state}.include? true
  end
  
  def self.groupByFlagState
    return Flag.group("druid", "state").size
  end
  
  def self.queryFlagGroup(flag_group, druid, state)
    return flag_group[[druid,state]] || 0
  end

  # get total flag unresolved count, or for a specific druid if you pass it in
  def self.unresolved_count(druid=nil)
    counts=Flag.where(:state=>Flag.open)
    counts=counts.where(:druid=>druid) if druid
    counts.size
  end
  
  def notify_me
    notification_state=="pending"
  end
  
  def notify_me=(value)
    notification_state=(value == true ? "pending" : nil) 
  end
    
  def check_user_id
    errors.add(:user_id, :not_valid) unless (user_id.nil? || user_id.is_a?(Integer))
  end
  
  def check_flag_type
    errors.add(:flag_type, :not_valid) unless FLAG_TYPES.include? flag_type.to_s
  end

  def check_notification_state
    errors.add(:notification_state, :not_valid) unless NOTIFICATION_STATES.include?(notification_state.to_s) || notification_state.blank?
  end
  
   def check_flag_state
    errors.add(:state, :not_valid) unless FLAG_STATES.values.include? state.to_s
  end 
  
  def resolved?
    (self.class.closed.include? state)
  end
  
  def state_display_name
    return FLAG_STATE_DISPLAYS[self.state]
  end

end
