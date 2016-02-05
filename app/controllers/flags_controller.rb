class FlagsController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this
  skip_load_resource :only => :create

  def index # all flags
    #noop
    render :nothing=>true
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

    @spammer=params[:description] # if this hidden field is filled in, its a spam bot
    @loadtime=params[:loadtime] # this is the time the page was rendered, if it is submitted too fast, its a spammer
    @druid=flag_info[:druid]

    @flag=Flag.create_new(flag_info,current_user) unless is_spammer?(0.5) # any click faster than 0.5 seconds is a spambot

    @all_flags=Flag.where(:druid=>@druid)
    @document=SolrDocument.find(@druid)

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
    @flag.state = {t('revs.flags.fixed')=>Flag.fixed, t('revs.flags.wont_fix')=>Flag.wont_fix, t('revs.flags.fixed')=>Flag.fixed, t('revs.flags.in_review')=>Flag.review}[params[t('revs.flags.resolve')]]
    if @flag.resolved? && @flag.notify_me
      @flag.notification_state='delivered'
      RevsMailer.flag_resolved(@flag).deliver
    end
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
    @message=t('revs.flags.removed')
    @druid=@flag.druid
    @flag.destroy
    @all_flags=Flag.where(:druid=>@druid)
    @document=SolrDocument.find(@druid)

    #If a different user is deleting the flag, penalize the creating user for spam.
    if(@flag.user_id != current_user.id) && !@flag.user.nil?
      @user = User.find(@flag.user_id)
      @user.spam_flags += 1
      @user.save
    end

    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end
  end

  # allow curators to bulk update flag states and apply comments to descriptions
  def bulk_update
    flag_update=params[:flag_update]
    if flag_update
      flag_ids=flag_update[:selected_flags]
      flag_ids.each do |id|
        flag=Flag.find(id)
        flag.move_to_description
        flag.save
      end
      flash[:success]=I18n.t('revs.flags.updated')
    end
    redirect_to flags_table_curator_tasks_path(params)
  end

end
