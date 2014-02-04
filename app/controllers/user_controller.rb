class UserController < ApplicationController
  
  #Class Vars
  
  before_filter :check_for_curator_logged_in, :only=>[:curator_update_flag_table]
  
  # user profile pages
  
  # public user profile page by ID (e.g. /user/134)
  def show
    @id=params[:id]
    @user=User.find_by_id(@id)
    render_profile  
  end
  
   
  # public user profile page by name (e.g. /user/peter)
  def show_by_name
    @name=params[:name]
    @user=User.find_by_username(@name)
    render_profile
  end
      
  # all of the user's annotations
  def annotations
    @name=params[:name]
    @user=User.find_by_username(@name)
    if @user
      @order=params[:order] || 'created_at DESC'    
      @annotations=@user.visible('annotations').order(@order).page params[:page] 
    else
      profile_not_found
    end
  end
  
  # all of the user's favorites
  def favorites
    @name=params[:name]
    @user=User.find_by_username(@name)
    if @user
      @order=params[:order] || 'created_at DESC'
      @favorites=@user.favorites.order(@order).page params[:page] 
    else
      profile_not_found
    end
  end
  
  #all of the user'sgalleries
  def galleries
    @name=params[:name]
     @user=User.find_by_username(@name)
     if @user
     else
       profile_not_found
     end
     
  end

  # all of the user's item edits
  def edits
    @name=params[:name]
    @user=User.find_by_username(@name)
    if @user
      @order=params[:order] || 'created_at DESC'    
      @edits=@user.visible('change_logs').order(@order).page params[:page] 
    else
      profile_not_found
    end
  end
  
  # all of the user's flags
  def flags
    @name=params[:name]
    @user=User.find_by_username(@name)
    s = params[:selection] || Flag.open
    @selection = s.split(',')
    
    if @user
      @order=params[:order] || 'created_at DESC'    
      @flags=flagListForStates(@selection, @user, @order)
      
    else
      profile_not_found
    end
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
  
  private
  def render_profile
    if (@user && (@user==current_user || @user.public == true)) # if this is the currently logged in user or the profile is public, show the profile
      render :show
    else
      profile_not_found
    end
  end
  
  def profile_not_found
    flash[:error]=t('revs.authentication.user_not_found')
    redirect_to previous_page  
  end
  
  

  
end
