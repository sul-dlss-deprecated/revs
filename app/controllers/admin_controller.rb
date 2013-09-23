class AdminController < ApplicationController

  before_filter :check_for_admin_logged_in

  def index
    
  end

end
