module ApplicationHelper

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
    opts[:facet].nil? ? val : link_to(val,catalog_index_path(:"f[#{opts[:facet]}][]"=>"#{val}"))
  end
  
  def show_formatted_list(mvf,opts={})
    mvf.collect do |val|
      if opts[:facet]
        output=link_to(val,catalog_index_path(:"f[#{opts[:facet]}][]"=>"#{val}"))
      else
        output=val
      end
    end.join(', ').html_safe
  end
  
  def render_locale_class
    "lang-#{I18n.locale}"
  end
  
  def user_profile_url
    return "" unless user_signed_in?
    if current_user.no_name_entered?
      user_profile_id_url(current_user.id)
    else
      user_profile_name_url([current_user.first_name,current_user.last_name].join('.'))
    end
  end
  
end
