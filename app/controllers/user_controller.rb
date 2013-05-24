class UserController < ApplicationController

  before_filter :check_for_any_user_logged_in, :only=>'preview'
  
  # public user profile page
  def show
    @id=params[:id]
    @name=params[:name]
    
    if @id # the user sent in an ID
      @users=User.where('id=? AND public=?',@id,true)
    else # the user sent in a name
      nameparts=@name.split('.')  
      @users=User.where('first_name=? AND last_name=? AND public=?',nameparts[0],nameparts[1],true)
    end
    
    if @users.size == 0
      flash[:error]='The user was not found or their profile is not public.'
      redirect_to previous_page
      return
    elsif @users.size > 1 # TODO for REVS-336: show a disambiguation page instead
      render :select
    else
      @user=@users.first
    end
  end
    
  # current logged in user profile page, always visible regardless of public visibility setting
  def preview
    @user=current_user
    render :show
  end
  
end
