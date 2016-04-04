Revs::Application.configure do

  config.eager_load = false

  # Settings specified here will take precedence over those in config/application.rb
  config.exception_error_page = false # show a friendly 500 error page and send notification exceptions if true
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Expands the lines which load the assets
  config.assets.debug = true

  config.middleware.use Rack::Attack

  # Revs App Configuration
  config.simulate_sunet_user = "sunetuser" # SET TO BLANK OR FALSE IN PRODUCTION (it should be ignored in production anyway) if this has a value, then this will simulate you being logged in as a sunet user
  config.restricted_beta = false # if set to true, then only beta users (and sunet users) can view the site
  config.use_editstore = false # if set to true, then all changes will be saved to editstore database (SHOULD BE TRUE IN PRODUCTION!)

  config.featured_contributors=[]# ['curator1','admin1','user1'] # array of usernames of featured contributors for about top contributors page...will be shown in this order, use an empty array if none
end
