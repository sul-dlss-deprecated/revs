class User < ActiveRecord::Base
    
  # user abilities and permissions are defined in the ability.rb class == if you add or change names here, you will need both
  #  update the ability class, and update the strings stored in the user "role" column
  ROLES=%w{admin curator user}
  DEFAULT_ROLE='user' # the default role that any logged in user will have
  
  # Include default devise modules. Others available are:
  # :token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :lockable, :timeoutable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :sunet, :password, :password_confirmation, :remember_me, :role, :bio, :first_name, :last_name, :public, :url, :login, :subscribe_to_mailing_list
  attr_accessor :subscribe_to_mailing_list # not persisted, just used on the signup form
  attr_accessor :login # virtual method that will refer to either email or username
  
  has_many :annotations, :dependent => :destroy
  has_many :flags, :dependent => :destroy
  before_validation :assign_default_role, :if=>lambda{no_role?}
  before_save :trim_names
  after_create :signup_for_mailing_list, :if=>lambda{subscribe_to_mailing_list=='1'}
  validate :check_role_name
  validates :username, :uniqueness => { :case_sensitive => false }
  validates :username, :length => { :in => 5..50}
  validates :username, :format => { :with => /\A\D.+/,:message => "must start with a letter" }
  include Blacklight::User
  
  def self.roles
    ROLES
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
      
  def self.create_new_sunet_user(sunet)
    user = User.new(:email=>"#{sunet}@stanford.edu",:sunet=>sunet,:username=>"#{sunet}@stanford.edu",:password => default_sunet_user_password, :password_confirmation => default_sunet_user_password, :role=>DEFAULT_ROLE)
    user.skip_confirmation!
    user.save!
    user
  end
  
  # passwords are irrelvant and never used for SUNET users, but we need to set one in the user table to make devise happy
  # we override the sign_in method from devise (in controllers/sessions_controller) to prevent SUNET users from using this password to login via the normal sign in form
  def default_sunet_user_password
    "password"
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
    errors.add(:role, "is not valid") unless ROLES.include? role.to_s
  end
  
  # Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  def to_s
    return username || sunet
  end
  
  def no_name_entered?
    first_name.blank? && last_name.blank?  
  end
  
  def full_name
    no_name_entered? ? 'unidentified' : [first_name,last_name].join(' ')
  end
    
  def role?(test_role)
    test_role.to_s.camelize == role
  end

  def no_role?
    role.blank?
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