class Admin::AdminController < ApplicationController 

  before_filter :check_for_admin_logged_in

  def check_for_admin_logged_in
    not_authorized unless can? :administer, :all
  end
  
end