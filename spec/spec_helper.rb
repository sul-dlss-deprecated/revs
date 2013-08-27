# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

# the following must match what are in the users.yml fixtures
def user_login
  'user1'   
end

def sunet_login
  'sunetuser@stanford.edu'
end

def curator_login
  'curator1'
end

def admin_login
  'admin1'
end

def beta_login
  'beta1'
end

def login_pw
  'password'
end

def login_as(login, password = nil)
  password ||= login_pw
  logout
  visit new_user_session_path
  fill_in "user_login", :with => login
  fill_in "user_password", :with => password
  click_button "submit"
end

def logout
  sign_out_button="Sign out"
  click_button(sign_out_button) if has_button?(sign_out_button)
end

# some helper methods to do some quick checks

# Annotations
def should_allow_annotations  
  page.should have_content('View/add annotations')
end

def should_not_allow_annotations  
  page.should_not have_content('View/add annotations')
end

# Flags
def should_allow_flagging
  page.should have_button('Flag this item')
  page.should_not have_css('#flag-details-link.hidden')
end

def should_not_allow_flagging
  page.should_not have_button('Flag this item')
end

def should_deny_access(path)
  visit path
  current_path.should == root_path
  page.should have_content('You are not authorized to perform this action.')
end

def should_allow_admin_section
  visit admin_users_path
  page.should have_content('Administer Users')
  current_path.should == admin_users_path  
end

def should_allow_curator_section
  visit curator_tasks_path
  page.should have_content('Flagged Items')
end

def unchanged(doc)
  doc.valid? && !doc.dirty? && doc.unsaved_edits == {}
end

def changed(doc,updates)
  doc.dirty? && doc.valid? && doc.unsaved_edits == updates
end

def editstore_entry(entry,params={})
  entry.field == params[:field] &&
    entry.new_value == params[:new_value] &&
    entry.old_value == params[:old_value] &&
    entry.druid == params[:druid] &&
    entry.operation == params[:operation] && 
    entry.state == Editstore::State.send(params[:state].to_s) 
end

def reindex_solr_docs(druids)
  add_docs = []
  druids=[druids] if druids.class != Array
  druids.each do |druid|
    add_docs << File.read(File.join("#{Rails.root}/spec/fixtures","#{druid}.xml"))
  end
  RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
end
  