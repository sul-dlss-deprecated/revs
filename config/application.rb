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

    config.middleware.insert 0, Rack::UTF8Sanitizer

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

    config.log_tags = [ lambda {|r| DateTime.now } ]

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

    # Make sure all image subdirectories are added to assets paths
    Dir.glob("#{Rails.root}/app/assets/images/**/").each do |path|
      config.assets.paths << path
    end

    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = VERSION

    config.version = VERSION # read from VERSION file at base of website

    # Revs App Specific Configuration
    config.stacks_url = YAML.load_file("#{Rails.root}/config/stacks.yml")[Rails.env]["url"]
    config.embed_location = "https://embed.stanford.edu/iframe?url=https://purl.stanford.edu"
    config.purl = "https://purl.stanford.edu"
    config.new_revs_digital_library_search_page = "http://library.revsinstitute.org/digital/search/searchterm"
    config.contact_us_topics = {'default'=>'revs.contact.select_topic', 'metadata'=>'revs.contact.metadata_issue', 'special collections'=>'revs.contact.special_collections','error'=>'revs.contact.problem','other'=>'revs.contact.other_questions'} # sets the list of topics shown in the contact us page
    config.contact_us_recipients = {'default'=>'digcoll@jirasul.stanford.edu','metadata'=>'digcoll@jirasul.stanford.edu','error'=>'digcoll@jirasul.stanford.edu','other'=>'digcoll@jirasul.stanford.edu','special collections'=>'specialcollections@stanford.edu'} # sets the email address for each contact us topic configed aboveend
    config.contact_us_cc_recipients = {'default'=>'revs-other@jirasul.stanford.edu', 'metadata'=>'revs-metadata-comment@jirasul.stanford.edu', 'error'=>'revs-problems@jirasul.stanford.edu','other'=>'revs-other@jirasul.stanford.edu'} # sets the CC email address for each contact us topic configed above

    config.show_item_counts_in_header = false # if set to true, we will show total item and collection counts in the header
    config.num_latest_user_activity = 3 # the latest number of flags/annotations to show on the user profile page
    config.num_flags_per_item_per_user = 5 # the number of times each user is allowed to flag a particular item
    #config.flag_sort_display = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_display_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name')}
    config.num_default_per_page = 25 # the default number of a given item to display per page (e.g. flags, favorites, galleries)
    config.num_default_per_page_collections = 12 # the default number of a collections and public galleries to display per page
    config.search_results_affected = false # set to true to show a message that search results may be impacted (useful during a full re-index)
    config.sunet_timeout_secs = 86400 # the number of seconds a sunet user can stay logged in before getting timeed out (this is separate than the devise config for regular users)
                                       # 1 day = 86400 seconds

#    config.site_message="The website will be down for scheduled maintenance today, July 8, at 3pm Pacific Time for approximately 30 minutes." # set to some string to show a message on the top of each message (like to advertise a known site outage) , leave blank for no message
#    config.site_message = 'Note: Content from The Revs Institute has now been removed from this website.  Revs Institute content can be found on the new Revs Digital Library at <a href="http://library.revsinstitute.org">http://library.revsinstitute.org</a>.  The Road & Track Collection is still available on this website, which is now called the Automobility Archive.'
    config.site_message = 'Note: This website will be shutting down soon.  All of the content from the Road & Track Collection will still be visible on the new Automobility Exhibit at <a href="https://exhibits.stanford.edu/automobility">https://exhibits.stanford.edu/automobility</a>.'

    # if the following configuration is not nil or a blank array, one of these questions will be asked at random when user's register to try and block spammy registrations
    # format is an array of hashes, the answer is not case sensitive
    config.reg_questions = []
    #   {:question=>'What is the name of the car company that manufacturers the Mustang?',:answer=>'Ford'},
    #   {:question=>'What is the first name of the founder of Ferrari?',:answer=>'Enzo'}
    # ]
    config.disable_new_registrations = true # set to true to disable new users from registering (useful in conjunction with disable_editing or if there is a sustained period of bogus registrations)
    config.disable_more_to_explore = true # set to true to disable more to explore on the home page
    config.disable_featured_galleries = true # set to true to disable featured galleries on the home page
    config.require_manual_account_activation = true # set to true to require an admin to manually activate any new account registrations
    config.new_registration_notification = 'petucket@stanford.edu' # email address to receive daily notifications of new registrations
    config.spam_reg_checks = true # set to false to skip spam registration checks (useful in testing)
    config.show_item_counts_in_header = false # if set to true, we will show total item and collection counts in the header
    config.disable_editing = true # if set to true, will disallow metadata editing, changing visibility and placeholder, the creation of annotations and flags - the things that can update a solr document or add to the metadata editing load
    config.show_galleries_in_nav = false # if set to true, then galleries and collections are shown in top navigation

  end
end

GOOGLE_ANALYTICS_CODE = "UA-7219229-17" # automobility archive
EDITSTORE_PROJECT='Revs'  # the name of your project in the editstore database -- this must exist in the edistore database "projects" table in both production and development to work properly
