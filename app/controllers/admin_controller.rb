class AdminController < ApplicationController

  before_filter :check_for_admin_logged_in
  before_filter :set_no_cache

  def index
    
  end

end
