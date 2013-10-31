class UserController < ApplicationController
  
  #Class Vars
  
  
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
      @order=params[:order] || 'druid'    
      @annotations=@user.annotations.order(@order).page params[:page] 
    else
      profile_not_found
    end
  end

  # all of the user's item edits
  def edits
    @name=params[:name]
    @user=User.find_by_username(@name)
    if @user
      @order=params[:order] || 'druid'    
      @edits=@user.metadata_updates.order(@order).page params[:page] 
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
      @order=params[:order] || 'druid'    
      @flags=flagListForStates(@selection, @user, @order)
      
    else
      profile_not_found
    end
  end
  
  def update_flag_table
    @curate_view = false 
    @selection = params[:selection].split(',')
    @user = current_user
    @flags = flagListForStates(@selection, current_user.id, params[:sort] || "druid")
    respond_to do |format|
       format.js { render }
    end
  end
  
  def curator_update_flag_table
    @curate_view = true 
    @user = current_user
    @selection = params[:selection].split(',') 
    @flags = flagListForStates(@selection, nil,params[:sort] || "druid")
    respond_to do |format|
       format.js { render }
    end
  end
  
  
  
  
  def flagListForStates(states, user, sort)
    flags = []
      
      if user == nil #curator, we want all flags
         temp = Flag.where(:state=>states).order(sort)
      else
        temp = Flag.where(:state=>states, :user_id=> @user.id).order(sort)
      end
     
    flags = temp || []  
      
    return Kaminari.paginate_array(flags).page(params[:pagina]).per(Flag.per_table_page)
  end
  
  private
  def render_profile
    if (@user && (@user==current_user || @user.public == true)) # if this is the currently logged in user or the profile is public, show the profile
      @latest_flags=@user.flags.order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
      @latest_annotations=@user.annotations.order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
      @latest_edits=@user.metadata_updates.order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
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
