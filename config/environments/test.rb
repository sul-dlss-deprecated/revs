Revs::Application.configure do

  config.eager_load = false
  
  # Settings specified here will take precedence over those in config/application.rb
  config.exception_error_page = false # show a friendly 500 error page if true
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Revs App Configuration  
  config.simulate_sunet_user = "sunetuser" # SET TO BLANK OR FALSE IN PRODUCTION (it should be ignored in production anyway) if this has a value, then this will simulate you being logged in as a sunet user
  config.purl_plugin_server = "test"
  config.purl_plugin_location = "//image-viewer.stanford.edu/assets/purl_embed_jquery_plugin.js"
  config.purl = "//purl.stanford.edu"
  config.restricted_beta = false # if set to true, then only beta users (and sunet users) can view the site
  config.use_editstore = true # if set to true, then all changes will be saved to editstore database (SHOULD BE TRUE IN PRODUCTION AND TEST!)
  config.show_galleries_in_nav = true # if set to true, then galleries is shown in top navigation

  config.featured_contributors=['curator1','admin1','user1'] # array of usernames of featured contributors for about top contributors page...will be shown in this order, use an empty array if none
end

Squash::Ruby.configure :api_host => 'https://squash-dev.stanford.edu',
                       :api_key => '20f28544-89ff-42f8-b310-4d79a70a9b29',
                       :disabled => true
