module DeviseHelper

  def devise_error_messages!

   return validation_errors(resource) # defined in application helper so we can use it for any model

 end

end
 