class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # NOTE: only certain actions are actually checked for permissions, therefore most actions are allowed by default
    # and do not need to be defined here.  Update, create and destroy actions are checked for permissions via the resourceful.rb
    # file, which acts as the superclass for most controllers.  All other actions by default are not checked and are fully allowed.  
    
    # Check the controllers to see which actions are protected.  Some UI elements are also not shown based on abilities 
    
    # By design, each user can only be in one role -- however, this file is coded so that if this is changed in the future, multiple roles support is possible
    
    # There are methods defined below as ROLENAME_actions that define what ROLENAME can do
    
    user ||= User.new # non-logged in user

    send("#{user.role.downcase}_actions",user) unless user.no_role?

    guest_actions(user)
            
  end
  
  # unlogged in users
  def guest_actions(user)
    # any user of the website (even those not logged in) can perform these actions
    can :read, [Annotation,Flag]
    can :index_by_druid, [Annotation, Flag]
  end
  
   # administrator can enter admin area and curator area and can peform all user actions
  def admin_actions(user)
    curator_actions(user)
    can :administer, :all
  end
  
  # curator role can enter curator area and can perform all user actions
  def curator_actions(user)
    user_actions(user)
    can :curate, :all
    can :bulk_update, :all
    can :update, :all
  end
  
  # logged in user
  def user_actions(user)
    can [:update,:destroy], [Annotation,Flag], :user_id => user.id # can update and destroy their own annotations and flags
    can :create, [Annotation,Flag] # can create new annotations and flags
  end
  
  
end
