class AdminController < ApplicationController

  before_filter :check_for_admin_logged_in

  def index
    @users = User.order('username').page(params[:page]).per(1)
  end

end
