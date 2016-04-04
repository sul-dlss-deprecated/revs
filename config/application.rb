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
    config.embed_location = "//embed.stanford.edu/iframe?url=https://purl.stanford.edu"
    config.purl = "//purl.stanford.edu"
    config.contact_us_topics = {'default'=>'revs.contact.select_topic', 'metadata'=>'revs.contact.metadata_issue','terms of use'=>'revs.contact.terms_of_use', 'special collections'=>'revs.contact.special_collections','error'=>'revs.contact.problem','other'=>'revs.contact.other_questions'} # sets the list of topics shown in the contact us page
    config.contact_us_recipients = {'default'=>'digcoll@jirasul.stanford.edu', 'terms of use'=>'library@revsinstitute.org','metadata'=>'digcoll@jirasul.stanford.edu','error'=>'digcoll@jirasul.stanford.edu','other'=>'digcoll@jirasul.stanford.edu','special collections'=>'specialcollections@stanford.edu'} # sets the email address for each contact us topic configed aboveend
    config.contact_us_cc_recipients = {'default'=>'revs-other@jirasul.stanford.edu', 'metadata'=>'revs-metadata-comment@jirasul.stanford.edu', 'error'=>'revs-problems@jirasul.stanford.edu','other'=>'revs-other@jirasul.stanford.edu'} # sets the CC email address for each contact us topic configed above

    # these collections are only available for non-commerical reproduction and will show a special statement instead of the use and reproduction statement in the item itself
    config.collections_available_for_noncommerical_reproduction =
      [ 'jh550nq3200', # Worner
        'zq905ny4367', # Grand Prix
        'ch493nk3954', # Tubbs
        'zg796vp9147', # European Motorsport
        'qn776mq9014', # Cabart
        'vm027cv8758', # Richley
        'wt886dn0556', # Derauw
        'wz243gf4151', # Chambers
        'my206bq1956'  # Royal Automobile Trophy
      ]

    # these collections have uncertain rights and we will show a special statement instead of the use and reproduction statement in the item itself
    config.collection_rights_uncertain =
      [ 'td221fy0182', # Breslauer
        'gw676ck6589', # Ludvigsen
        'yt502zj0924', # Craig
      ]

    config.revs_reuse_link='http://revsinstitute.org/order-images/'

    config.collier_archive_name = 'Revs Institute® Archives' # this is the name of the collier archive, it will be added to records if it does not yet exist when saving for remediating records that existed before we had multiple archives

    config.disable_editing = false # if set to true, will disallow metadata editing, changing visibility and placeholder, the creation of annotations and flags - the things that can update a solr document or add to the metadata editing load
    config.num_latest_user_activity = 3 # the latest number of flags/annotations to show on the user profile page
    config.num_flags_per_item_per_user = 5 # the number of times each user is allowed to flag a particular item
    #config.flag_sort_display = {FLAG_STATES[:open]=> I18n.t('revs.flags.open_state_display_name'),FLAG_STATES[:fixed]=> I18n.t('revs.flags.fixed_state_display_name'),FLAG_STATES[:wont_fix]=> I18n.t('revs.flags.wont_fix_state_display_name')}
    config.num_default_per_page = 25 # the default number of a given item to display per page (e.g. flags, favorites, galleries)
    config.num_default_per_page_collections = 12 # the default number of a collections and public galleries to display per page
    config.search_results_affected = false # set to true to show a message that search results may be impacted (useful during a full re-index)
    config.sunet_timeout_secs = 86400 # the number of seconds a sunet user can stay logged in before getting timeed out (this is separate than the devise config for regular users)
                                       # 1 day = 86400 seconds

#    config.site_message="The website will be down for scheduled maintenance today, July 8, at 3pm Pacific Time for approximately 30 minutes." # set to some string to show a message on the top of each message (like to advertise a known site outage) , leave blank for no message

    config.site_message = ""

  end
end

GOOGLE_ANALYTICS_CODE = "UA-7219229-17" # revs digital library
EDITSTORE_PROJECT='Revs'  # the name of your project in the editstore database -- this must exist in the edistore database "projects" table in both production and development to work properly
