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
  attr_accessible :email, :sunet, :password, :password_confirmation, :remember_me, :role, :bio, :first_name, :last_name, :public, :url, :subscribe_to_mailing_list 
  attr_accessor :subscribe_to_mailing_list # not persisted, just used on the signup form
  
  has_many :annotations, :dependent => :destroy
  has_many :flags, :dependent => :destroy
  before_validation :assign_default_role
  after_create :signup_for_mailing_list, :if=>lambda{subscribe_to_mailing_list=='1'}
  validate :check_role_name
  
  include Blacklight::User
  
  def self.roles
    ROLES
  end
  
  def self.create_new_sunet_user(sunet)
    user = User.new(:email=>"#{sunet}@stanford.edu",:sunet=>sunet,:password => 'password', :password_confirmation => 'password', :role=>DEFAULT_ROLE)
    user.skip_confirmation!
    user.save!
    user
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
    return email || sunet
  end
  
  def no_name_entered?
    first_name.blank? && last_name.blank?  
  end
  
  def full_name
    no_name_entered? ? 'unidentified' : [first_name,last_name].join(' ').squeeze(' ')
  end
  
  def is_webauth?
    !sunet.blank?
  end
    
  def role?(test_role)
    test_role.to_s.camelize == role
  end

  def no_role?
    role.blank?
  end
  
  def assign_default_role
    self.role=DEFAULT_ROLE if no_role?
  end
  
  # update the lock status if needed
  def update_lock_status(lock)
    if lock && locked_at.blank?
      lock_access!
    elsif !locked_at.blank?
      unlock_access!
    end
  end
  
end