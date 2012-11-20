class AboutController < ApplicationController 
  # Overriding the action in the params because we want to use the Show template
  # to hold the common About page code and sidebar info. The Show template
  # includes a call to a partial (name corresponding to the action in the params)
  # with the actual page content.
  before_filter :show

  def show
    render :show
  end

  # Need an empty action for each About page, and a partial with the same name
  # containing the actual page content.
  def project
  end
  def contact
  end
end