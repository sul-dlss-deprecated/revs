class UserController < ApplicationController
    
  before_filter :check_for_curator_logged_in, :only=>[:curator_update_flag_table] # only curators can reach this action
  before_filter :check_for_profile_visible, :only=>[:show,:show_by_name,:favorites] # these pages are only visible for the current user or public profiles
  before_filter :check_for_profile_existence, :except=>[:show,:show_by_name,:favorites] # these pages are visible to anyone
  
  # user profile pages
  
  # public user profile page by ID (e.g. /user/134)
  def show
  end
  
  # public user profile page by name (e.g. /user/peter)
  def show_by_name
    render :show
  end
      
  # all of the user's annotations
  def annotations
    @order=params[:order] || 'created_at DESC'    
    @annotations=@user.visible('annotations').order(@order).page params[:page] 
  end

  # all of the user's favorites, only show if the profile is public
  def favorites
    @order=params[:order] || 'created_at DESC'
    @favorites=Kaminari.paginate_array(@user.favorites.order(@order)).page(current_page).per(SavedItem.favorites_per_page)
  end

  # all of the user's item edits
  def edits
    @order=params[:order] || 'created_at DESC'    
    @edits=@user.visible('change_logs').order(@order).page params[:page] 
  end
  
  # all of the user's flags
  def flags
    s = params[:selection] || Flag.open
    @selection = s.split(',')    
    @order=params[:order] || 'created_at DESC'    
    @flags=flagListForStates(@selection, @user, @order)      
  end
  
  def update_flag_table
    @curate_view = false 
    @selection = params[:selection].split(',')
    @user = User.where(:username=>params[:username]).first
    @flags = flagListForStates(@selection, @user, params[:sort] || "druid")
    respond_to do |format|
       format.js { render }
    end
  end
  
  def curator_update_flag_table
    @curate_view = true 
    @selection = params[:selection].split(',') 
    @flags = flagListForStates(@selection, nil,params[:sort] || "druid")
    respond_to do |format|
       format.js { render }
    end
  end

  
  def flagListForStates(states, user, sort)
    flags = []
      
      if user == nil #curator, we want all flags
         temp = Flag.scoped
         temp = temp.where(:state=>states).order(sort)
      else
        temp = Flag.scoped
        temp = User.visibility_filter(temp,'flags')
        temp = temp.where(:state=>states, :user_id=> @user.id).order(sort)
      end
     
    flags = temp || []  
      
    return Kaminari.paginate_array(flags).page(params[:pagina]).per(Flag.per_table_page)
  end
  
end
