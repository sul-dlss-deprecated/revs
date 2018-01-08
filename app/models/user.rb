class User < ActiveRecord::Base

  include Blacklight::User

  extend FriendlyId
  friendly_id :username, use: [:finders]

  # class generated with CarrierWave
  mount_uploader :avatar, AvatarUploader
  validates_integrity_of  :avatar
  validates_processing_of :avatar

  # user abilities and permissions are defined in the ability.rb class == if you add or change names here, you will need to both
  #  update the ability class, and update the strings stored in the user "role" column (only if role names change)
  ROLES=%w{admin curator beta user}
  DEFAULT_ROLE='user' # the default role that any logged in user will have

  # Include default devise modules. Others available are:
  # :token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :lockable, :timeoutable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessor :subscribe_to_mailing_list, :registration_question_number, :registration_answer # not persisted, just used on the signup form
  attr_accessor :login # virtual method that will refer to either email or username

  # all "regular" has_many associations are done via custom methods below so we can add visibility filtering for items
  # the "all_CLASS" has_many associations are provided for convience, and to facilitate dependent destroying easily
  has_one :favorites_list, -> {where gallery_type:"favorites"}, :dependent => :destroy, :class_name=>'Gallery'
  has_many :all_galleries, :class_name=>'Gallery', :dependent=>:destroy
  has_many :all_annotations, :class_name=>'Annotation', :dependent=>:destroy
  has_many :all_change_logs, :class_name=>'ChangeLog', :dependent=>:destroy
  has_many :all_flags, :class_name=>'Flag', :dependent=>:destroy

  before_validation :assign_default_role, :if=>lambda{no_role?}
  before_save :trim_names
  after_create :signup_for_mailing_list, :if=>lambda{subscribe_to_mailing_list=='1'}
  after_create :create_default_favorites_list # create the default favorites list when accounts are created
  after_create :inactivate_account, :if=>lambda{Revs::Application.config.require_manual_account_activation == true && !sunet_user?}
  after_save :create_default_favorites_list # create the default favorites list if it doesn't exist when a user logs in

  validate :check_role_name
  validate :registration_answer_correct, :on => :create, :if=>lambda{Revs::Application.config.spam_reg_checks == true && !Revs::Application.config.reg_questions.blank?}
  validates :username, :uniqueness => { :case_sensitive => false }
  validates :username, :length => { :in => 5..50}
  validates :username, :format => { :with => /\A\D.+/,:message => "must start with a letter" }

  delegate :can?, :cannot?, :to => :ability # this saves us some typing so we can ask user.can? instead of user.ability.can?

  #### class level methods
  def self.create_new_sunet_user(sunet)
    password=self.create_sunet_user_password
    username=self.create_sunet_username(sunet)
    user = User.new(:email=>"#{sunet}@stanford.edu",:sunet=>sunet,:username=>username,:password => password, :password_confirmation => password, :role=>DEFAULT_ROLE)
    user.skip_confirmation!
    user.save!
    user
  end

  # passwords are irrelvant and never used for SUNET users, but we need to set one in the user table to make devise happy
  # we override the sign_in method from devise (in controllers/sessions_controller) to prevent SUNET users from logging in using this password anyway
  def self.create_sunet_user_password
    SecureRandom.hex(16)
  end

  # sunet users need usernames, but we shouldn't make it their email address to avoid exposing it -- but they still need to be unique
  def self.create_sunet_username(sunet)
    suggested_username=sunet.ljust(5,'1234') # start with sunet as a default, padding with '1234' to get to minimum of 5 character username, but confirm it will be unique, if not just keep incrementing with integers
    i=0
    loop do
       i+=1
       user_count=User.where(:username=>suggested_username).size
       break if user_count == 0
       suggested_username="#{sunet}_#{i}"
    end
    return suggested_username
  end

  def self.roles
    ROLES
  end

  # only returning visible items for given class and query depending on user ability passed in
  def self.visibility_filter(things,class_name,user=nil)
    (user.blank? || user.cannot?(:view_hidden, SolrDocument)) ? things.joins("LEFT OUTER JOIN items on items.druid = #{class_name}.druid").where("items.visibility_value = #{SolrDocument.visibility_mappings[:visible]} OR items.visibility_value is null") : things
  end

  # inactive and never logged in users older than this timeframe will be removed (default to 2 weeks)
  def self.purge_inactive(timeframe=2.weeks.ago)
    unconfirmed_users=User.where(:active=>false,:sunet=>'',:login_count=>0).where("updated_at < ?",timeframe)
    num_users = unconfirmed_users.size
    puts "Destroying #{num_users} inactive and non logged in users older than #{timeframe}"
    unconfirmed_users.each do |user|
      puts "...destroying '#{user.username}'"
      user.destroy
    end
    return num_users
  end

  #### class level methods

  # used for spammy users; will set their account to inactive and destroy any of the galleries, flags and annotations
  def ban
    self.active = false
    self.public = false
    save
    all_galleries.destroy_all
    all_annotations.destroy_all
    all_flags.destroy_all
  end

  def curator?
    %w{admin curator}.include? role
  end

  # indicate which galleries should be shown based on the user passed in
  def gallery_visibility_filter(user)
    all_visibilities=[]
    all_visibilities << 'public' # anyone can see public galleries
    all_visibilities << 'curator' if !user.blank? && user.can?(:curate, :all) # curators can see any curator galleries
    all_visibilities << 'private' if !user.blank? && user == self
    return all_visibilities
  end

  ### has_many custom associations, so we can add visibility filtering
  def all_saved_items
    SavedItem.includes(:gallery).where(:'galleries.user_id'=>id)
  end

  def saved_items(user=nil)
    self.class.visibility_filter(SavedItem.includes(:gallery).where(:'galleries.user_id'=>id),'saved_items',user)
  end

 # get the user's galleries,  pass in a second user (like the logged in user) to decide what other galleries should be returned as well
  def galleries(user=nil)
    Gallery.where(:user_id=>id,:gallery_type=>'user',:visibility => gallery_visibility_filter(user))
  end

  # get the user's favorites, pass in a second user (like the logged in user) to decide if hidden item favorites should be returned as well
  def favorites(user=nil)
    self.class.visibility_filter(favorites_list.saved_items(user),'saved_items',user)
  end

  # get the user's annotations, pass in a second user (like the logged in user) to decide if hidden item annotations should be returned as well
  def annotations(user=nil)
    self.class.visibility_filter(Annotation.where(:user_id=>id),'annotations',user)
  end

  # get the user's flags, pass in a second user (like the logged in user) to decide if hidden item flags should be returned as well
  def flags(user=nil)
    self.class.visibility_filter(Flag.where(:user_id=>id),'flags',user)
  end

  # get all change logs
  def change_logs(user=nil)
    self.class.visibility_filter(ChangeLog.where(:user_id=>id),'change_logs',user)
  end

  # get just metadata updates from the change logs
  def metadata_updates(user=nil)
    change_logs(user).where(:user_id=>id,:operation=>'metadata update')
  end
  ### associations

  # create the default favoritest list unless it already exists (done at account create and login, just to be sure it exists)
  def create_default_favorites_list
    if favorites_list.blank?
      new_favorites_list=Gallery.new
      new_favorites_list.user_id=id
      new_favorites_list.gallery_type=:favorites
      new_favorites_list.visibility=:private
      new_favorites_list.title=I18n.t('revs.favorites.head')
      new_favorites_list.save
      self.reload
    end
  end

  def inactivate_account
    self.update_attribute(:active,false)
  end

  def activate_account
    self.update_attribute(:active,true)
  end

  # determines if account is active (could be locked or manually made inactive)
  def active_for_authentication?
    super && active
  end

  def inactive_message
    active ? super : :account_has_been_deactivated
  end

  def after_database_authentication
    if active_for_authentication?
      self.increment!(:login_count)
      create_default_favorites_list
    end
  end

  # override devise method --- stanford users are never timed out; regular users are timed out according to devise rules
  def timedout?(last_access)
    sunet_user? && !last_access.nil? ? ((Time.now-last_access) > Revs::Application.config.sunet_timeout_secs) : super
  end

  # a helper getter method to get to the visibility status of the favorites list
  def favorites_public
    favorites_list.public
  end

  # a helper setter method to set to the visibility status of the favorites list
  def favorites_public=(value)
    favorites_list.update_column(:visibility,(value.to_s == "true" ? :public : :private))
  end

  # Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  def to_s
    self.public ? full_name : (username || sunet)
  end

  # override devise behavior for signs so that it allows the user to signin with either username or email
  def self.find_first_by_auth_conditions(tainted_conditions, opts={})
    conditions = tainted_conditions.dup
    if login = conditions.delete(:login) # if we are on the login page, allow either username or login to work
      self.where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      to_adapter.find_first(devise_parameter_filter.filter(conditions).merge(opts))
    end
  end

  def sunet_user?
    !sunet.blank?
  end

  def is_webauth?
    sunet_user?
  end

  def signup_for_mailing_list
    RevsMailer.mailing_list_signup(:from=>email).deliver
  end

  def check_role_name
    errors.add(:role, :not_valid) unless ROLES.include? role.to_s
  end

  def registration_answer_correct
    errors.add(:registration_answer, :not_correct) unless !registration_answer.blank? && (registration_answer.strip.downcase == Revs::Application.config.reg_questions[registration_question_number.to_i][:answer].downcase)
  end

  def no_name_entered?
    first_name.blank? && last_name.blank?
  end

  def full_name
    no_name_entered? ? username : [first_name,last_name].join(' ')
  end

  def role?(test_role)
    test_role.to_s.camelize == role
  end

  def no_role?
    role.blank?
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def init_flag_user(current_user)
    return flagListForStates([Flag.open], current_user)
  end

  # update the lock status if needed
  def update_lock_status(lock)
    if lock && locked_at.blank?
      lock_access!
    elsif !locked_at.blank?
      unlock_access!
    end
  end

  protected
  def assign_default_role
    self.role=DEFAULT_ROLE
  end

  def trim_names
    first_name.strip!
    last_name.strip!
  end

end
