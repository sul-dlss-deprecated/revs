class UserController < ApplicationController
  
  # user profile page
  def show
    id=params[:id]
    name=params[:name]
    if id # the user sent in an ID
      users=User.where('id=? AND public=?',params[:id],true)
    else # the user sent in a name
      nameparts=name.split('.')  
      users=User.where('first_name=? AND last_name=? AND public=?',nameparts[0],nameparts[1],true)
    end
    
    if users.size == 0
      flash[:error]='The user was not found or their profile is not public.'
      redirect_to request.referrer || root_path
      return
    elsif users.size > 1
      flash[:error]='More than one user was found with that name.'
      redirect_to request.referrer || root_path    
    else
      @user=users.first
    end
  end
  
end
