class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.

    # NOTE: only certain actions are actually checked for permissions, therefore most actions are allowed by default
    # and do not need to be defined here.  Update, create and destroy actions are checked for permissions via the resourceful.rb
    # file, which acts as the superclass for most controllers.  All other actions by default are not checked and are fully allowed.   
    
    # by design, each user can only be in one role -- however, this file is coded so that if this is changed in the future, multiple roles support is possible
    
    user ||= User.new # guest user

    if user.role? :admin # administrator can do everything, and can enter admin area
      can :administer, :all
      can :curate, :all
    end
    
    if user.role? :curator # curator role
      can :curate, :all
    end
            
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
 
  end
  
end
