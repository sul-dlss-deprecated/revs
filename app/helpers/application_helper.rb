module ApplicationHelper

  def on_home_page
    request.path == '/' && params[:f].blank?
  end

  def on_collections_pages
    Rails.application.routes.recognize_path(request.path)[:controller] == "catalog" && !on_home_page
  end
  
  def on_about_pages
    Rails.application.routes.recognize_path(request.path)[:controller] == 'about'
  end
  
end
