class User < ActiveRecord::Base
    
  # Include default devise modules. Others available are:
  # :token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :lockable, :timeoutable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :sunet, :password, :password_confirmation, :remember_me, :role_id, :bio, :first_name, :last_name, :public, :url
  
  has_many :annotations
  has_many :flags
  belongs_to :role
  before_save :assign_default_role
    
  include Blacklight::User
  
  def self.create_new_sunet_user(sunet)
    user = User.new(:email=>"#{sunet}@stanford.edu",:sunet=>sunet,:password => 'password', :password_confirmation => 'password')
    user.skip_confirmation!
    user.save!
    user
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
    no_role? ? false : test_role.to_s.camelize == role.name
  end
  
  def role_name
    no_role? ? "" : role.name
  end

  def no_role?
      return !!self.role_id.blank?
  end
  
  def assign_default_role
    role=Role.user if no_role?
  end
  
end