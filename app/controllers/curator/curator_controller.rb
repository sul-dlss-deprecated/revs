class Curator::CuratorController < ApplicationController 

  before_filter :check_for_curator_logged_in

  def check_for_curator_logged_in
    not_authorized unless can? :curate, :all
  end

end