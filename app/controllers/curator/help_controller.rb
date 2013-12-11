class Curator::HelpController < ApplicationController

  before_filter :check_for_curator_logged_in

end
