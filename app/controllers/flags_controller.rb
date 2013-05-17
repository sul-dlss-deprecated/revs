class FlagsController < ApplicationController

  def index
    druid=params[:druid]
    @flags=Flag.where(:druid=>druid)
    respond_to do |format|
      format.js { render }
    end
  end

  def create
    
    flag_info=params[:flag]
    @flag=Flag.create(:flag_type=>flag_info[:flag_type],:comment=>flag_info[:comment],:druid=>flag_info[:druid],:user_id=>current_user.id)
    @all_flags=Flag.where(:druid=>flag_info[:druid])
    @message='The item was flagged.'
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end
    
  end

  def show
    @flag=Flag.find(params[:id])
    respond_to do |format|
      format.js { render }
    end 
  end
  
  def update
    flag_info=params[:flag]
    @message='The flag was updated.'
    
    @flag=Flag.find(params[:id])
    @flag.comment=flag_info[:comment]
    @flag.flag_type=flag_info[:flag_type] if flag_info[:flag_type]
    @flag.cleared=Time.now if flag_info[:cleared]
    @flag.save
    @all_flags=Flag.where(:druid=>flag_info[:druid])
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}      
      format.js { render }
    end    
  end

  def destroy
    @flag=Flag.find(params[:id])
    @message='The flag was removed.'
    @druid=@flag.druid
    @flag.destroy
    @all_flags=Flag.where(:druid=>@druid)
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}      
      format.js { render }
    end     
  end
    
end
