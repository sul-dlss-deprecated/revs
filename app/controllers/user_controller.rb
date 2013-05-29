class UserController < ApplicationController
  
  # public user profile page by ID
  def show
    @id=params[:id]
    @user=User.find_by_id(@id)
    if (@user && (@user==current_user || @user.public == true)) # if this is the currently logged in user or the profile is public, show the profile
      render :show
    else
      profile_not_found
    end
  end
  
  # public user profile page by name
  def show_by_name
    @name=params[:name]
    @user=User.find_by_username(@name)
    if (@user && (@user==current_user || @user.public == true)) # if this is the currently logged in user or the profile is public, show the profile
      render :show
    else
      profile_not_found
    end
  end
  
  private
  def profile_not_found
    flash[:error]='The user was not found or their profile is not public.'
    redirect_to previous_page  
  end
  
end
