module ApplicationHelper

  def available_sizes
   sizes=["'thumb'","'zoom'"]
   sizes+=["'small'","'medium'","'large'","'xlarge'","'full'"] if sunet_user_signed_in?
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
  
end
