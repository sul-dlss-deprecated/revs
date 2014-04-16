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

    send("#{user.role.downcase}_actions",user) unless user.no_role? # this lets us define abilities by creating methods called "ROLENAME_actions"

    can_act_as_guest_user(user)
    
    beta_actions(user) if user.sunet_user?  # sunet users are automatically included in the beta
            
  end
  
  # roles defintions (ROLENAME_actions)

  # unlogged in users

  # logged in user
  def user_actions(user)
    can_act_as_logged_in_user(user) unless Revs::Application.config.restricted_beta # also have logged in privileges if we are not in beta
  end
        
   # logged in beta user, gets logged in user actions
  def beta_actions(user)
    can_act_as_logged_in_user(user)
  end
  
  # curator role can do anything a logged in user can + curate and update metadata
  def curator_actions(user)
    can_act_as_logged_in_user(user)
    can_curate
    can_update_metadata
  end  
  
   # administrator can do anything a logged in user can, a curator can, as well as adminster
  def admin_actions(user)
    can_act_as_logged_in_user(user)
    can_curate
    can_update_metadata
    can_administer
  end
  
  # defined abilities
  private
  def can_act_as_guest_user(user)
    # any user of the website (even those not logged in) can perform these actions
    can_view_about_pages # anyone can see the about and home page no matter what
    unless Revs::Application.config.restricted_beta # if we are in private beta, guests can do nothing else, otherwise they can view items and read annotations and flags
      can_view_items
      can_read_annotations
      can_read_flags
      can_flag_anonymous if user.id.nil? # if this is really an anonymous user, add this ability -- if they are logged in, it will added in later specifically for logged in users
    end
  end
  
  def can_act_as_logged_in_user(user)
    can_view_about_pages
    can_view_items
    can_read_annotations
    can_read_flags
    can_annotate(user)
    can_flag_logged_in(user)
    can_save_favorites_and_galleries(user)
  end
  
  def can_view_about_pages
    can :read, [:home_page,:about_pages]
  end

  def can_view_items
    can :read,:collections_page
    can :read,:item_pages
    can :read,:search_pages   
  end
  
  def can_read_annotations
    can :read, Annotation    
    can :index_by_druid, Annotation 
  end
  
  def can_read_flags
    can :read, Flag    
    can :index_by_druid, Flag  
    can :update_flag_table, User 
  end
  
  def can_annotate(user)
    can :create, Annotation # can create new annotations
    can [:update,:destroy], Annotation, :user_id => user.id # can update and destroy their own annotations
  end

  def can_save_favorites_and_galleries(user)
    can :create, SavedItem # can create new saved items
    can :create, Gallery, :user_id=>user.id # can create new galleries for themselves
    can [:update,:destroy,:cancel], SavedItem, :user_id => user.id # can update and destroy their own Saved Items
    can [:update,:destroy], Gallery, :user_id => user.id # can update and destroy their own Galleries
  end
  
  def can_flag_anonymous
    can :create, Flag # can create new flags  
    can :add_new_flag_to, SolrDocument do |doc|
      doc.flags.where("user_id is null OR user_id=''").where(:state=>Flag.open).count < Revs::Application.config.num_flags_per_item_per_user
    end    
  end
  
  def can_flag_logged_in(user)
    can :create, Flag # can create new flags  
    can [:update,:destroy], Flag, :user_id => user.id # can update and destroy their own annotations and flags
    can :add_new_flag_to, SolrDocument do |doc|
         doc.flags.where(:user_id=>user.id, :state=>Flag.open).count < Revs::Application.config.num_flags_per_item_per_user
    end # can only add new flags to a solr document with less than a certain number of flags for any given user
  end
    
  def can_curate
    can :curate, :all
    can :destroy, Flag
    can :destroy, Annotation
    can :resolve, Flag
    can :update, Flag
    can :curator_update_flag_table, User  
    can :view_hidden, SolrDocument
  end
  
  def can_update_metadata
    can :bulk_update_metadata, :all
    can :update_metadata, :all 
  end
  
  def can_administer
    can :administer, :all
  end
  
end
