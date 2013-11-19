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

def should_deny_access_for_beta(path)
  visit path
  current_path.should == root_path
  page.should have_content("The Revs Digital Library is currently in limited beta release.")
end

def should_allow_admin_section
  visit admin_dashboard_path
  page.should have_content('Administrator Dashboard')
  current_path.should == admin_dashboard_path
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


def login_as_user_and_goto_druid(user, druid)
  #logout, just in case
  logout  
  #login as the provided user
  login_as(user)
  item_page=catalog_path(druid)
  visit item_page
end

def remove_flag(user, druid, content)
  login_as_user_and_goto_druid(user, druid)
  find_flag_by_content_and_click_button(content, @remove_button)
end

def find_flag_by_content_and_click_button(content, button)
   get_a_flag_by_content(content).click_button(button)
end

def resolve_flag_wont_fix(user, druid, content, resolve_message)
  login_as_user_and_goto_druid(user, druid)
  resolve_flag(content, resolve_message, @wont_fix_button)
end

def resolve_flag_fix(user, druid, content, resolve_message)
  login_as_user_and_goto_druid(user, druid)
  resolve_flag(content, resolve_message, @fix_button)
end

def resolve_flag(content, resolve_message, button)
  f = get_a_flag_by_content(content)
  fill_in @resolution_field, :with=>resolve_message
  click_button button
end

def get_a_flag_by_content(content)
  all_flags = page.all(:css, '.flag-info')

    all_flags.each do |f|
      if f.has_content?(content)
        return f
      end 
    end
    return nil 
end


def add_a_flag(user, druid, content)
  login_as_user_and_goto_druid(user,druid)
  fill_in @comment_field, :with=>content
  click_button @flag_button
end

def check_flag_was_created(user, druid, content, flag_count)
  # check the page for the correct messages
  check_page_for_flag(user, druid, content)
  
  #check the database for the comment and ensure the flag count was incremented
  return check_database_for_flag(user, flag_count, content)
  
  
end

def check_page_for_flag(user, druid, content)
  item_page=catalog_path(druid)
  current_path.should == item_page
  page.should have_content(I18n.t('revs.flags.created'))
  page.should have_content(content)
  page.should have_button(@remove_button)
end

def check_database_for_flag(user, expected_total_flags, content)
  user=User.find_by_username(user)
  Flag.count.should == expected_total_flags
  flag=Flag.last
  flag.comment.should == content
  flag.flag_type.should == @default_flag_type
  flag.user=user
  return flag.id
end

def check_flag_was_deleted(user, druid, expected_total_flags)
  page.should have_content(I18n.t('revs.flags.removed'))
  Flag.count.should == expected_total_flags
  Flag.where(:user_id=>User.find_by_username(user).id,:druid=>druid).size.should == 0 
end

def check_flag_was_marked_wont_fix(content, expected_total_flags, resolution, flag_id)
  check_flag_resolution_on_page(content, I18n.t('revs.flags.resolved_wont_fix'), expected_total_flags)
  check_flag_resolution_in_db(content, resolution, Flag.wont_fix, flag_id)
end

def check_flag_was_marked_fix(content, expected_total_flags, resolution, flag_id)
  check_flag_resolution_on_page(content, I18n.t('revs.flags.resolved_fix'), expected_total_flags)
  check_flag_resolution_in_db(content, resolution, Flag.fixed, flag_id)
end



def check_flag_resolution_on_page(content, message, expected_total_flags)
  page.should have_content(message)
  Flag.count.should == expected_total_flags
  
  #Make sure this flag isn't displaying since it has been resolved
  get_a_flag_by_content(content).should == nil
end

def check_flag_resolution_in_db(content, resolution, state, id)
   flags = Flag.all
   for f in flags
     if(f.id == id)
       f.state.should == state
       f.resolution == resolution
     end
   end
end



def get_user_spam_count(username)
  return User.find_by_username(username).spam_flags
end

def has_content_array(all_content)
  all_content.each do |a|
    page.should have_content(a)
  end
end

def has_no_content_array(all_content)
  all_content.each do |a|
    page.should have_no_content(a)
  end
end


def random_mixed_case_string()
  s = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
  string = (0...50).map{ s[rand(s.length)] }.join
  return string if string != string.downcase and string != string.upcase #return if not all caps and not all lower case
  return random_mixed_case_string()  #We managed to get a string with entirely the same case, try again.    
end

def array_of_unique_strings(len)
  return_array = []
  while return_array.size <= len
    return_array.append(random_mixed_case_string())
    return_array = return_array.map{|i| i.downcase}.uniq #Groom out ones that aren't entirely unique
    #TODO:  Could be smarter and just groom at the end of the loop due to low odds of duplicates, then just use recursion to finish filling up the array.  However since I'm only calling this <12 items, not worth it.
  end
  return return_array
end

def update_solr_field(druid, field, value)
  
  doc = SolrDocument.find(druid)
  #TODO: Refractor me out to a helper
  assigner = '='
  assigner = '_mvf'+assigner if SolrDocument.field_mappings[field][:multi_valued]
  #End
  doc.send(field.to_s+assigner,value)
  doc.save

end

def search_no_result(search)
  visit search_path(:q=>search)
  page.should have_content(I18n.t('revs.search.search_results'))
  page.should have_content('No entries found')  #TODO:  Figure out why not in /lib/locales/en.yml
end

def searches_no_result(search, complex)
  full_search_array(search, complex).each do |query|
    search_no_result(query)
  end
  
end

def searches_direct_route(search, druid, complex)
  full_search_array(search, complex).each do |query|
    search_direct_route(query, druid)
  end
end

def search_direct_route(search, druid)
  visit search_path(:q=>search)
  current_path.should == item_path(druid)
end

def search_multiple_results(search, expected) 
  pag_limit = 25 #Default for Kaminari
  visit search_path(:q=>'photo')
  page.should have_content('Results')
  page.should have_content("1 - #{expected} of #{expected}") if expected <= 25
  page.should have_content("1 - #{expected} of #{25}") if expected > 25
  page.should have_content('The David Nadig Collection of the Revs Institute')
  page.should have_content('The John Dugdale Collection of the Revs Institute')
end

def searches_multiple_results(search, expected, complex)
  full_search_array(search, complex).each do |query|
    search_multiple_results(query, expected)
  end
end

def full_search_array(search, complex)
  return [search] if not complex
  
  searches = [search, search.upcase, search.downcase]
  subs = search.split(" ")
  subs.each do |s|
    searches.append(s)
    searches.append(s.upcase)
    searches.append(s.downcase)
  end
  return searches.uniq
end