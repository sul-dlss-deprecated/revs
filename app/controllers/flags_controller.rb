class FlagsController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this
  
  def index # all flags
    @flags=Flag.all
    respond_to do |format|
      format.js { render }
    end
  end

  def index_by_druid # flags for a specific image
    druid=params[:id]
    @flags=Flag.where(:druid=>druid)
    respond_to do |format|
      format.js { render }
    end
  end
  
  def create
    
    flag_info=params[:flag]
    @flag=Flag.create_new(flag_info,current_user)
    @all_flags=Flag.where(:druid=>flag_info[:druid])
    @document=SolrDocument.find(flag_info[:druid])
    @message=t('revs.flags.created')
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end
    
  end

  def show
    respond_to do |format|
      format.js { render }
    end 
  end
  
  def update
    flag_info=params[:flag]    
    @flag.resolution = flag_info[:resolution]
    @flag.resolved_time=Time.now
    @flag.resolving_user = current_user.id
    @flag.state = {t('revs.flags.fixed')=>Flag.fixed, t('revs.flags.wont_fix')=>Flag.wont_fix}[params[t('revs.flags.resolve')]]
    @flag.save
    @message={t('revs.flags.fixed')=>t('revs.flags.resolved_fix'), t('revs.flags.wont_fix')=>t('revs.flags.resolved_wont_fix')}[params[t('revs.flags.resolve')]]
    @all_flags=Flag.where(:druid=>flag_info[:druid])
    respond_to do |format|
    format.html { flash[:success]=@message
                  redirect_to previous_page}      
    format.js { render }
     
    end    
  end

  def destroy
    @flag=Flag.find(params[:id])
    @message=t('revs.flags.removed')
    @druid=@flag.druid
    @flag.destroy
    @all_flags=Flag.where(:druid=>@druid)
    @document=SolrDocument.find(@druid)
    
    #If a different user is deleting the flag, penalize the creating user for spam.
    if(@flag.user_id != current_user.id) && !@flag.user.nil?
      @user = User.find_by_id(@flag.user_id)
      @user.spam_flags += 1 
      @user.save
    end
    
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}      
      format.js { render }
    end     
  end
  
  

    
end
