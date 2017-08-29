# encoding: utf-8
require 'addressable/uri'

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller

   include Blacklight::Controller
   include DateHelper
   extend DateHelper
   include SolrQueryHelper

   require 'blacklight/catalog/search_context'
   include Blacklight::Catalog::SearchContext

  rescue_from Exception, :with=>:exception_on_website

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  helper_method :application_name,:tag_line,:current_role,:on_home_page,:on_collections_page,:on_galleries_page,:on_about_pages,:on_detail_page,:show_terms_dialog?,:sunet_user_signed_in?,:in_search_result?,:list_type_interpolator,:item_type_interpolator
  helper_method :paging_params,:extract_paging_params,:from_gallery?,:from_favorites?,:is_logged_in_user?,:sort_field,:whitelist_sort_fields
  layout "revs"

  protect_from_forgery

  before_action :configure_permitted_parameters, if: :devise_controller?

  prepend_before_filter :simulate_sunet, :if=>lambda{Rails.env !='production' && !session["WEBAUTH_USER"].blank?} # to simulate sunet login in development, set a parameter in config/environments/ENVIRONMENT.rb
  before_filter :signin_sunet_user, :if=>lambda{sunet_user_signed_in? && !user_signed_in?} # signin a sunet user if they are webauthed but not yet logged into the site

  before_filter :repository_counts, :if=>lambda{!fragment_exist?("navbar")} # fragment cache counts for performance

  rescue_from CanCan::AccessDenied do |exception|
    not_authorized(:additional_message=>exception.message)
  end

  def application_name
    t('revs.digital_library')
  end

  def tag_line
    t('revs.tagline')
  end

  def repository_counts
    @total_collections=SolrDocument.all_collections.size
    @total_images=SolrDocument.total_images
  end

  def is_spammer?(load_time=5)
    !@spammer.blank? || @loadtime.blank? || ((Time.now - @loadtime.to_time) < load_time) # user filled in a hidden form field or submitted the form in less than specified load_time (default=5) seconds
  end

  def previous_page(params={})
    url = Addressable::URI.parse(request.referrer || root_path)
    query = url.query_values || {}
    url.query_values = query.merge(params)
    url.to_s
  end

  def strip_params(url,params=[])
    url = Addressable::URI.parse(url)
    query = url.query_values || {}
    query.delete_if {|key,value| params.include? key }
    url.query_values = query
    url.to_s
  end

  def strip_all_params(url)
    url = Addressable::URI.parse(url)
    url.query_values=nil
    url.to_s
  end

  def store_referred_page
    if [new_user_session_url,new_user_session_path,new_user_registration_url,new_user_registration_path,new_user_password_path,new_user_password_url,new_user_confirmation_path,new_user_confirmation_url,new_user_unlock_path,new_user_unlock_url,edit_user_password_path,edit_user_password_url].include?(strip_all_params(previous_page)) # referral pages cannot be sign in or sign up page
      session[:login_redirect] = root_path
    else
      session[:login_redirect] = previous_page
    end
  end

  def after_sign_in_path_for(resource)
    session[:login_redirect]  || root_path
  end

  def redirect_home_if_signed_in # if the user is already signed in and they try to go to login/reg page, just send them to the home page to prevent infinite redirects
    if user_signed_in?
      session[:login_redirect] = nil
      redirect_to root_path
      return true
    end
  end

  # pass in a user, tells you if it's the currently logged in user
  def is_logged_in_user?(user)
    user_signed_in? && user == current_user
  end

  def after_sign_out_path_for(resource_or_scope) # back to home page after sign out
    root_path
  end

  def after_update_path_for(resource) # after a user updates their account info or profile, take them back to their account info page
    user_path(current_user.username)
  end

  def no_sunet_users
    not_authorized unless (user_signed_in? && !current_user.sunet_user?)
  end

  def check_for_any_user_logged_in
    not_authorized unless user_signed_in?
  end

  def check_for_user_logged_in
    not_authorized unless user_signed_in? && current_user.role?(:user)
  end

  def check_for_admin_logged_in
    not_authorized unless can? :administer, :all
  end

  def check_for_curator_logged_in
    not_authorized unless can? :curate, :all
  end

  def in_search_result?
    @previous_document || @next_document
  end

  def ajax_only
    unless request.xhr?
      render :nothing=>true, :status => 405
      return
    end
  end

  def set_no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def routing_error
    # flash.now[:error]=t('revs.routing_error')
    render "application/404", :formats=>[:html], :status => :not_found
    return false
  end

  def not_authorized(params={})

    additional_message=params[:additional_message]
    replace_message=params[:replace_message]

    message = replace_message || t('revs.messages.not_authorized')
    message+=" " + additional_message unless additional_message.blank?

    respond_to do |format|
      format.html { redirect_to :root, :alert=>message.html_safe}
      format.xml  { render :xml => message, :status=>401 }
      format.json { render :json => {:message=>"^#{message}"}, :status=>401}
    end
    return false

  end

  # only used for testing sunet in development; sets the environment variable manually for testing purposes
  def simulate_sunet
    request.env["WEBAUTH_USER"]=session["WEBAUTH_USER"] unless Rails.env=='production'
  end

  def signin_sunet_user
     # if we have a webauthed user who is not yet signed in, let's sign them in or create them a new user account if needed
    user=(User.where(:sunet=>request.env["WEBAUTH_USER"]).first || User.create_new_sunet_user(request.env["WEBAUTH_USER"]))
    sign_in user unless request.path==user_session_path
    user.increment!(:login_count)
  end

  def sunet_user_signed_in?
    !request.env["WEBAUTH_USER"].blank?
  end

  def on_home_page
    request.path==root_path && params[:f].blank? && params[:q].blank? && params[:range].blank?
  end

  def on_detail_page
    controller_path=='catalog' && action_name=='show'
  end

  def on_collections_page
    controller_path=='collection'
  end

  def on_galleries_page
    controller_path=='galleries'
  end

  def on_about_pages
    controller_path == 'about'
  end

  def seen_terms_dialog?
    cookies[:seen_terms] || false
  end

  def show_terms_dialog?
   false # do not show terms dialog as per email with Trina Purcell on August 28, 2014
   # %w{production staging}.include?(Rails.env) && !seen_terms_dialog?   # we are using the terms dialog to show a warning to users who are viewing the site on production or staging
  end

  def accept_terms
    cookies[:seen_terms] = { :value => true, :expires => 7.days.from_now } # they've seen it now, don't show it for another week
    redirect_to (params[:return_to] || :root)
  end

  def list_type_interpolator(gallery_type)
    (gallery_type == 'favorites' ? t('revs.favorites.plural') : t('revs.user_galleries.singular'))
  end

  def item_type_interpolator(gallery_type)
    (gallery_type == 'favorites' ? t('revs.favorites.singular') : t('revs.collection_members.items_name'))
  end

  def current_role
    current_user ? current_user.role : 'none'
  end

  def current_ability
    current_user ? current_user.ability : User.new.ability
  end

  # add paging params to an incoming hash of other parameters
  def paging_params(others={})
    others.merge({:order=>@order,:per_page=>@per_page,:page=>@current_page})
  end

  # get the current paging params and set instance variables
  def get_paging_params
   @current_page = params[:page] || 1
   @order=sort_field(params[:order])
   @per_page=(params[:per_page] || Revs::Application.config.num_default_per_page).to_i
   @from=params[:from]
   @search=params[:search]
  end

  # pass all querystring sort parameters through a whitelist and set a default if no valid field was found
  def sort_field(sort_param,default='created_at DESC')
    whitelist_sort_fields[sort_param] || default
  end

  # the allowed sort orders that can be passed in via the querystring, map these to actual values to pass to SQL to prevent sql injection
  def whitelist_sort_fields
    {
      'user_id' => 'user_id ASC',
      'email' => 'email ASC',
      'title' => 'title ASC',
      'items_title' => 'items.title ASC',
      'visibility' => 'visibility ASC',
      'views' => 'views DESC',
      'username' => 'username ASC',
      'last_name' => 'last_name ASC',
      'sunet' => 'sunet ASC',
      'role' => 'role ASC',
      'state' => 'state ASC',
      'login_count_desc' => 'login_count DESC',
      'created_at_desc' => 'created_at DESC',
      'updated_at_desc' => 'updated_at DESC',
      'confirmed_at_desc' => 'confirmed_at DESC',
      'num_flags_desc' => 'num_flags DESC',
      'flags_created_at_desc' => 'flags.created_at DESC',
      'flags_updated_at_desc' => 'flags.updated_at DESC',
      'annotations_created_at_desc' => 'annotations.created_at DESC',
      'annotations_updated_at_desc' => 'annotations.updated_at DESC',
      'num_annotations_desc' => 'num_annotations DESC',
      'num_favorites_desc' => 'num_favorites DESC',
      'num_galleries_desc' => 'num_galleries DESC',
      'items_title_asc' => 'items.title ASC',
      'num_edits_desc' => 'num_edits DESC',
      'saved_items_updated_at_desc' => 'saved_items.updated_at DESC',
      'galleries_saved_items_count_desc' => 'galleries.saved_items_count DESC',
    }
  end

  # pass all querystring sort parameters through a whitelist and set a default if no valid field was found
  def filter_field(filter_param,default='all')
    whitelist_filter_fields[filter_param] || default
  end

  # the allowed filters that can be passed in via the querystring, map these to actual values to pass to SQL to prevent sql injection
  def whitelist_filter_fields
    {'stanford'=>'stanford',
    'non-stanford'=>'non-stanford',
    'all'=>'all',
    'user'=>'user',
    'curator'=>'curator',
    'featured'=>'featured',
    'public'=>'public',
    'private'=>'private'
    }
  end

  def is_integer?(input)
    return true if input.nil?
    begin
      Integer(input)
      true
    rescue
      false
    end
  end

  # extract relevant paging params from params hash to add to some links
  def extract_paging_params(params)
    params.dup.keep_if {|k,v| ['order','page','per_page'].include? k}
  end

  def from_gallery?
    !params[:gallery_id].blank?
  end

  def from_favorites?
    !params[:favorite_user_name].blank?
  end


  def exception_on_website(exception)

    @exception=exception
    Honeybadger.notify(exception)

    if Revs::Application.config.exception_error_page
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render "application/500", :formats=>[:html], :status => 500
        return false
      else
        raise(@exception)
     end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:password,:password_confirmation,:username, :email,:subscribe_to_mailing_list) }
  end

end
