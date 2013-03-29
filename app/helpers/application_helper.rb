module ApplicationHelper

  def on_home_page
    request.path == '/' && params[:f].blank?
  end
  
  def available_sizes
   sizes=["'thumb'","'zoom'"]
   sizes+=["'small'","'medium'","'large'","'xlarge'","'full'"] unless sunet_user.blank?
   return sizes.join(',')    
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

  def on_collections_pages
    Rails.application.routes.recognize_path(request.path)[:controller] == "catalog" && !on_home_page
  end
  
  def on_about_pages
    Rails.application.routes.recognize_path(request.path)[:controller] == 'about'
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
  
end
