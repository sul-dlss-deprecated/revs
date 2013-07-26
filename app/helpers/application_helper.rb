module ApplicationHelper

  include DateHelpers
  
  def validation_errors(obj)

    return '' if obj.errors.empty?

    messages = obj.errors.full_messages.map { |msg| content_tag(:li, msg) }.join

    html = <<-HTML
    <div class="alert alert-error alert-block"> <a class="close" href="#" data-dismiss="alert">x</a>
     #{messages}
    </div>
    HTML

    html.html_safe
    
  end
  
  # pass in a user, tells you if it's the currently logged in user
  def is_logged_in_user?(user)
    user_signed_in? && user == current_user
  end
    
  # pass in a user, if it's the currently logged in user, you will always get the fullname; otherwise you will get the appropriate name for public display  
  def display_user_name(user)
     is_logged_in_user?(user) ? user.full_name : user.to_s
  end
  
  def available_sizes
   sizes=["'thumb'","'zoom'"]
   sizes+=["'small'","'medium'","'large'","'xlarge'","'full'"] if sunet_user_signed_in?
   return sizes.join(',')    
  end
  
  def home_or_back
    url = request.referrer || root_path
    link_to t('revs.nav.go_back'),url
  end
  
  def title_no_revs(title)
    title.gsub(" of the Revs Institute","")
  end
  
  # take in a hash of options for the contact us form, and then pass the values of the hash through the translation engine
  def translate_options(options)
    result={}
    options.each {|k,v| result.merge!({k=>I18n.t(v)})}
    return result
  end

  def show_linked_value(val,opts={})
    opts[:facet].blank? ? val : link_to(val,catalog_index_path(:"f[#{SolrDocument.field_mappings[opts[:facet].to_sym][:field]}][]"=>"#{val}"))
  end
  
  def show_formatted_list(mvf,opts={})
    return "" if mvf.blank?
    return show_linked_value(mvf,opts) if mvf.class != Array
    return mvf.collect {|val|show_linked_value(val,opts)}.join(', ').html_safe
  end
  
  def render_locale_class
    "lang-#{I18n.locale}"
  end

  def item_link(item,opts={})
    if item.nil?  
      return t('revs.curator.not_found')
    else
      name=opts[:truncate] ? truncate(item.title) : item.title
      return link_to name,catalog_path(item.id)
    end
  end
  
  def user_annotations_count(user)
    user.annotations.count
  end

  def user_flags_count(user)
    user.flags.count
  end
  
  def on_edit_page
    ["edit","update"].include? action_name
  end
  
  def on_user_profile_page
    ['show','show_by_name'].include?(action_name) && controller_name == 'user'
  end
  
  def in_curator_edit_mode
    (session[:curator_edit_mode].blank? || session[:curator_edit_mode] == 'false') ? false : can?(:curate,:all)
  end
  
  # used to build the drop down menu of available fields for bulk updating -- add the text to be shown to user and the field in solr doc and Editstore fields table
  def bulk_update_fields
    [
      ['Title','title'],
      ['Formats','formats'],
      ['Years','years_mvf'],
      ['Date','full_date'],
      ['Description','description'],
      ['Marques','marque_mvf'],
      ['Models','vehicle_model_mvf'],
      ['Model Years','model_year_mvf'],
      ['People','people_mvf'],
      ['Entrant','entrant'],
      ['Current Owner','current_owner'],
      ['Venue','venue'],
      ['Track','track'],
      ['Event','event'],
      ['Location','location'],
      ['Group/Class','group_class'],
      ['Race Data','race_data'],
      ['Photographer','photographer']
    ]
  end
  
end