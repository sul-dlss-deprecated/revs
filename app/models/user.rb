class User < ActiveRecord::Base

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
  attr_accessible :username, :email, :sunet, :password, :password_confirmation, :remember_me,
                  :role, :bio, :first_name, :last_name, :public, :url, :twitter, :login,
                  :subscribe_to_mailing_list, :subscribe_to_revs_mailing_list, :active, 
                  :avatar, :avatar_cache, :remove_avatar, :login_count
  attr_accessor :subscribe_to_mailing_list, :subscribe_to_revs_mailing_list # not persisted, just used on the signup form
  attr_accessor :login # virtual method that will refer to either email or username
  
  has_many :annotations, :dependent => :destroy
  has_many :flags, :dependent => :destroy
  has_many :change_logs, :dependent => :destroy
  has_one  :favorites_list, :conditions=>'gallery_type="favorites"', :dependent => :destroy, :class_name=>'Gallery'
  has_many :galleries, :conditions=>'gallery_type="user"', :dependent => :destroy
  has_many :saved_items, :through=>:galleries

  before_validation :assign_default_role, :if=>lambda{no_role?}
  before_save :trim_names
  after_create :signup_for_mailing_list, :if=>lambda{subscribe_to_mailing_list=='1'}
  after_create :signup_for_revs_institute_mailing_list, :if=>lambda{subscribe_to_revs_mailing_list=='1'}
  after_save :create_default_favorites_list # create the default favorites list if it doesn't exist when a user logs in
  after_create :create_default_favorites_list # create the default favorites list when accounts are created

  validate :check_role_name
  validates :username, :uniqueness => { :case_sensitive => false }
  validates :username, :length => { :in => 5..50}
  validates :username, :format => { :with => /\A\D.+/,:message => "must start with a letter" }
  include Blacklight::User

  delegate :can?, :cannot?, :to => :ability # this saves us some typing so we can ask user.can? instead of user.ability.can?
  
  #### class level methods
  def self.create_new_sunet_user(sunet)
    password=self.create_sunet_user_password
    user = User.new(:email=>"#{sunet}@stanford.edu",:sunet=>sunet,:username=>"#{sunet}@stanford.edu",:password => password, :password_confirmation => password, :role=>DEFAULT_ROLE)
    user.skip_confirmation!
    user.save!
    user
  end
  
  # passwords are irrelvant and never used for SUNET users, but we need to set one in the user table to make devise happy
  # we override the sign_in method from devise (in controllers/sessions_controller) to prevent SUNET users from logging in using this password anyway
  def self.create_sunet_user_password
    SecureRandom.hex(16)
  end

  def self.roles
    ROLES
  end
  
  # only returning visible items for given class and query
  def self.visibility_filter(things,class_name)
    things.joins("LEFT OUTER JOIN items on items.druid = #{class_name}.druid").where("items.visibility_value = #{SolrDocument.visibility_mappings[:visible]} OR items.visibility_value is null")    
  end
  #### class level methods

  ### other associations
  # get the user's favorites 
  def favorites
    favorites_list.saved_items 
  end

  # get just metadata updates from the change logs, grouped by druid
  def metadata_updates
    visible('change_logs').group('change_logs.druid').where(:operation=>'metadata update')
  end
  ### other associations

  # create the default favoritest list unless it already exists (done at account create and login, just to be sure it exists)
  def create_default_favorites_list
    if favorites_list.blank?
      new_favorites_list=Gallery.create(:user_id=>id,:gallery_type=>:favorites,:title=>I18n.t('revs.favorites.head')) 
      self.reload
    end
  end

  # determines if account is active (could be locked or manually made inactive)
  def active_for_authentication?
    super && active
  end
  
  def inactive_message
    active ? super : :account_has_been_deactivated
  end
  
  def after_database_authentication
    self.increment!(:login_count)
    create_default_favorites_list
  end
 
  def visible(class_name)
    visible=eval("self.#{class_name}")
    visible=self.class.visibility_filter(visible,class_name)
    visible=visible.where(:operation=>'metadata update') if class_name=='change_logs' 
    return visible   
  end
  
  # override devise method --- stanford users are never timed out; regular users are timed out according to devise rules
  def timedout?(last_access)
    sunet_user? ? false : super
  end
  
  # Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  def to_s
    self.public ? full_name : (username || sunet) 
  end
  
  # override devise behavior for signs so that it allows the user to signin with either username or email
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
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

  def signup_for_revs_institute_mailing_list
    RevsMailer.revs_institute_mailing_list_signup(:from=>email).deliver 
  end
  
  def check_role_name
    errors.add(:role, :not_valid) unless ROLES.include? role.to_s
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