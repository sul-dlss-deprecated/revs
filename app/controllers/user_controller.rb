class UserController < ApplicationController
    
  before_filter :load_user_profile, :except=>[:update_flag_table,:curator_update_flag_table] # we need to be sure the profile exists before doing anything
  before_filter :get_paging_params, :only=>[:annotations,:favorites,:galleries,:edits,:flags]
  
  authorize_resource
  
  # user profile pages
  
  def show
    @page_title=I18n.t('revs.user.user_dashboard',:name=>(is_logged_in_user?(@user) ? t('revs.user.your') : "#{@user.to_s}'s"))
  end    

  # all of the user's annotations
  def annotations
    @annotations=@user.annotations(current_user).includes(:item).order(@order).page(@current_page).per(@per_page)
    @page_title="#{@user.to_s}: #{I18n.t('revs.annotations.plural')}"
  end

  # all of the user's favorites (visibility set on the favorites list)
  def favorites
    @manage=params[:manage]
    @view=params[:view] || "grid"
    unsorted_favorites = @user.favorites(current_user)
    
    #If the user has just been deleted favorites, @current_page might exceed the number of favorites
    max_pages = unsorted_favorites.count / @per_page
    
    #Add in one extra page for any overflows over the current amount
    max_pages += 1 if unsorted_favorites.count % @per_page != 0   

    #Reset @current_page if needed
    @current_page = max_pages.to_s if @current_page.to_i > max_pages
    
    @saved_items=Kaminari.paginate_array(unsorted_favorites.order(@order)).page(@current_page).per(@per_page)
    @page_title="#{@user.to_s}: #{I18n.t('revs.favorites.head')}"
    
  end
  
 def galleries
   @galleries=@user.galleries(current_user).page(@current_page).per(@per_page)
   @page_title="#{@user.to_s}: #{I18n.t('revs.nav.galleries')}"
 end
 
  # all of the user's item edits
  def edits
    @order="change_logs.#{@order}" if @order.downcase == 'created_at desc'
    @edits=@user.metadata_updates.order(@order).page(@current_page).per(@per_page)
    @page_title="#{@user.to_s}: #{I18n.t('revs.curator.edits')}"
  end
  
  # all of the user's flags
  def flags
    s = params[:selection] || Flag.open
    @selection = s.split(',')    
    @flags=flagListForStates(@selection, @user, @order)      
    @all_flag_count=@user.flags.count
    @page_title="#{@user.to_s}: #{I18n.t('revs.flags.plural')}"
  end
  
  def update_flag_table
    @curate_view = false 
    @username=params[:username]
    @selection = params[:selection].split(',')
    @user = User.find(@username)
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
         temp = Flag.where(:state=>states).includes(:item).order(sort)
      else
        temp = user.flags(current_user).includes(:item).where(:state=>states, :user_id=> @user.id).order(sort)
      end
     
    flags = temp || []  
      
    return Kaminari.paginate_array(flags).page(@current_page).per(Revs::Application.config.num_default_per_page)
  end
  
  private  
  def load_user_profile
    begin
      @user = User.find(params[:id])
    rescue
      profile_not_found
      return
    end      
    @user.create_default_favorites_list # create the default favorites list if for some reason it does not exist
    @latest_annotations=@user.annotations(current_user).order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
    @latest_flags=@user.flags(current_user).where(:state=>Flag.open).order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
    @latest_edits=@user.metadata_updates(current_user).order('change_logs.created_at desc').limit(Revs::Application.config.num_latest_user_activity)
    @latest_galleries=@user.galleries(current_user).order('created_at desc').limit(Revs::Application.config.num_latest_user_activity)
    @latest_favorites=@user.favorites(current_user).order('saved_items.created_at desc').limit(Revs::Application.config.num_latest_user_activity)
  end
  
  def profile_not_found
    flash[:error]=t('revs.authentication.user_not_found')
    redirect_to root_path 
  end
  
end
