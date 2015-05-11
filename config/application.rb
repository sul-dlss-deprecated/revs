require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

VERSION = File.read('VERSION')

module Revs
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/validators)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    config.i18n.enforce_available_locales = true

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found)
    config.i18n.fallbacks = true

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Custom i18n.load_path to pick up locale files in subdirectories
    config.i18n.load_path += Dir["#{Rails.root.to_s}/config/locales/**/*.{rb,yml}"]
        
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.active_record.raise_in_transactional_callbacks = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true    
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = VERSION

    config.version = VERSION # read from VERSION file at base of website                                                                                                                                                                                                                                                   

    # Revs App Specific Configuration
    config.stacks_url = YAML.load_file("#{Rails.root}/config/stacks.yml")[Rails.env]["url"]                                                                                                                                                                                                                                 
    config.contact_us_topics = {'default'=>'revs.contact.select_topic', 'metadata'=>'revs.contact.metadata_issue','terms of use'=>'revs.contact.terms_of_use', 'error'=>'revs.contact.problem','other'=>'revs.contact.other_questions'} # sets the list of topics shown in the contact us page
    config.contact_us_recipients = {'default'=>'digcoll@jirasul.stanford.edu', 'terms of use'=>'ldrake@chmotorcars.com','metadata'=>'digcoll@jirasul.stanford.edu','error'=>'digcoll@jirasul.stanford.edu','other'=>'digcoll@jirasul.stanford.edu'} # sets the email address for each contact us topic configed aboveend
    config.contact_us_cc_recipients = {'default'=>'revs-other@jirasul.stanford.edu', 'metadata'=>'revs-metadata-comment@jirasul.stanford.edu', 'error'=>'revs-problems@jirasul.stanford.edu','other'=>'revs-other@jirasul.stanford.edu'} # sets the CC email address for each contact us topic configed above

    config.collections_not_available_for_reproduction = ['td221fy0182','jh550nq3200','kv107xd8164'] # these collections are not available for reproduction and will show a special statement instead of the use and reproduction statement in the item itself...currently Breslauer, Bochroch and Worner
    
    config.revs_reuse_link='http://revsinstitute.org/research-education/permission-to-use/'
    
    config.num_latest_user_activity = 3 # the latest number of flags/annotations to show on the user profile page     
    config.num_flags_per_item_per_user = 5 # the number of times each user is allowed to flag a particular item
    #config.flag_sort_display = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_display_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name')}
    config.num_default_per_page = 25 # the default number of a given item to display per page (e.g. flags, favorites, galleries)
    config.num_default_per_page_collections = 12 # the default number of a collections and public galleries to display per page

    config.sunet_timeout_secs = 86400 # the number of seconds a sunet user can stay logged in before getting timeed out (this is separate than the devise config for regular users)
                                       # 1 day = 86400 seconds
  end
end

GOOGLE_ANALYTICS_CODE = "UA-7219229-17" # revs digital library
EDITSTORE_PROJECT='Revs'  # the name of your project in the editstore database -- this must exist in the edistore database "projects" table in both production and development to work properly