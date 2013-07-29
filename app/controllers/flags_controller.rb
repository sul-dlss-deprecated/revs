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
    @flag.update_attributes(:flag_type=>flag_info[:flag_type],:comment=>flag_info[:comment],:druid=>flag_info[:druid],:user_id=>current_user.id)
    @flag.save
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
    @flag.comment=flag_info[:comment]
    @flag.flag_type=flag_info[:flag_type] if flag_info[:flag_type]
    @flag.cleared=Time.now if flag_info[:cleared]
    @flag.save
    @message=t('revs.flags.updated')
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
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}      
      format.js { render }
    end     
  end
    
end
