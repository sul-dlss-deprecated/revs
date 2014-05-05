class UserController < ApplicationController
    
  before_filter :load_user_profile, :except=>[:update_flag_table,:curator_update_flag_table] # we need to be sure the profile exists before doing anything
  before_filter :confirm_public, :only=>[:show,:show_by_name,:favorites]
  before_filter :confirm_active, :except=>[:update_flag_table,:curator_update_flag_table]
  
  # TODO we should be able to do the confirmation of confirm_public and confirm_active in the Ability class via cancan, but I could not get it to work
  load_and_authorize_resource
  
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
    get_paging_params
    @annotations=@user.visible('annotations').order(@order).page(@current_page).per(@per_page)
  end

  # all of the user's favorites, only show if the entire profile is public (enfornced with before_filter above)
  def favorites
    get_paging_params
    unsorted_favorites = @user.favorites
    
    #If the user has just been deleted favorites, @current_page might exceed the number of favorites
    max_pages = unsorted_favorites.count / @per_page
    
    #Add in one extra page for any overflows over the current amount
    max_pages += 1 if unsorted_favorites.count % @per_page != 0   

    #Reset @current_page if needed
    @current_page = max_pages.to_s if @current_page.to_i > max_pages
    
    @saved_items=Kaminari.paginate_array(unsorted_favorites.order(@order)).page(@current_page).per(@per_page)
  end
  
 def galleries
   get_paging_params
   @galleries=@user.galleries
   @galleries=@galleries.where(:public=>true) unless @user == current_user # only show public galleries listed unless it is the current user
   @galleries=@galleries.page(@current_page).per(@per_page)
 end
 

  # all of the user's item edits
  def edits
    get_paging_params
    @order="change_logs.#{@order}" if @order.downcase == 'created_at desc'
    @edits=@user.visible('change_logs').group('change_logs.druid').order(@order).page(@current_page).per(@per_page)
  end
  
  # all of the user's flags
  def flags
    get_paging_params
    s = params[:selection] || Flag.open
    @selection = s.split(',')    
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
      
    return Kaminari.paginate_array(flags).page(params[:pagina]).per(Revs::Application.config.num_default_per_page)
  end
  
  private  
  # we need to be sure the user is viewing an active profile (or is an administrator, who can do all)
  def confirm_active
    profile_not_found unless @user.active == true || can?(:administer, :all)
  end

  # we need to be sure the user is viewing a public profile (or is themselves or an administrator, who can do all)  
  def confirm_public
    profile_not_found unless @user == current_user || @user.public == true || can?(:administer, :all)
  end
  
end
