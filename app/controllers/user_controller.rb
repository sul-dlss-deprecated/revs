class UserController < ApplicationController
  
  before_filter :set_num_to_show_latest
  
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
      @annotations=Annotation.where(:user_id=>@user.id).order(@order).page params[:page] 
    else
      profile_not_found
    end
  end

  # all of the user's flags
  def flags
    @name=params[:name]
    @user=User.find_by_username(@name)
    if @user
      @order=params[:order] || 'druid'    
      @flags=Flag.where(:user_id=>@user.id).order(@order).page params[:page] 
    else
      profile_not_found
    end
  end
  
  private
  def render_profile
    if (@user && (@user==current_user || @user.public == true)) # if this is the currently logged in user or the profile is public, show the profile
      @latest_flags=@user.flags.order('created_at desc').limit(@num_to_show_latest)
      @latest_annotations=@user.annotations.order('created_at desc').limit(@num_to_show_latest)
      render :show
    else
      profile_not_found
    end
  end
  
  def profile_not_found
    flash[:error]='The user was not found or their profile is not public.'
    redirect_to previous_page  
  end
  
  private 
  
  # the number of latest annotations/flags to show on the user profile page
  def set_num_to_show_latest
    @num_to_show_latest=3
  end
  
end
