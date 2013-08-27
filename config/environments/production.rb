Revs::Application.configure do  
  # Settings specified here will take precedence over those in config/application.rb
  config.exception_error_page = true # show a friendly 500 error page if true
  config.exception_recipients = '' # list of email addresses, comma separated, that will be notified when an exception occurs - leave blank for no emails
  config.action_mailer.default_url_options = { :host => 'revslib.stanford.edu' }

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  config.cache_store = :memory_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  
  GA.tracker = "UA-7219229-17" # revs digital library
  
end
Revs::Application.config.simulate_sunet_user = false # SET TO BLANK OR FALSE IN PRODUCTION (it should be ignored in production anyway) if this has a value, then this will simulate you being logged in as a sunet userRevs::Application.config.purl_plugin_server = "prod"
Revs::Application.config.purl = "//purl.stanford.edu"
Revs::Application.config.purl_plugin_server = "prod"
Revs::Application.config.purl_plugin_location = "//image-viewer.stanford.edu/javascripts/purl_embed_jquery_plugin.js"
Revs::Application.config.restricted_beta = true # if set to true, then only beta users (and sunet users) can view the site