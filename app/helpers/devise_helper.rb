module DeviseHelper

 def devise_error_messages!
  return '' if resource.errors.empty?

   messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join

   html = <<-HTML
   <div class="alert alert-error alert-block"> <a class="close" href="#" data-dismiss="alert">x</a>
    #{messages}
   </div>
   HTML

   html.html_safe
 end

end
 