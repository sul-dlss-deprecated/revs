class UserController < ApplicationController

  before_filter :check_for_any_user_logged_in, :only=>'me'
  
  # public user profile page by ID
  def show
    @id=params[:id]
    @user=User.find_by_id(@id)
    if (@user==current_user || @user.public == true) # if this is the currently logged in user or the profile is public, show the profile
      render :show
    else
      profile_not_found
    end
  end
  
  # public user profile page by name
  def show_by_name
    @name=params[:name]
    nameparts=@name.split('.')  
    @users=User.where('first_name=? AND last_name=? AND public=?',nameparts[0],nameparts[1],true)
    if @users.size == 0
       profile_not_found
     elsif @users.size > 1 # show a disambiguation page instead
       render :select
     else # only one user found, render the show page
       @user=@users.first
       render :show
     end
  end
  
  # current logged in user profile page, always visible regardless of public visibility setting
  def me
    @user=current_user
    render :show
  end
  
  private
  def profile_not_found
    flash[:error]='The user was not found or their profile is not public.'
    redirect_to previous_page  
  end
  
end
