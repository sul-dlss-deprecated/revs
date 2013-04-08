class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :lockable, :timeoutable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :sunet, :password, :password_confirmation, :remember_me
  
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
  
  def is_webauth?
    !sunet.blank?
  end
    
end