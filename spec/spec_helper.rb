RSpec::Expectations.configuration.warn_about_potential_false_positives = false

def item_druids
  return  ["bb004bn8654","bg152pb0116", "dd482qk0417", "hj660zx8618", "jg267fg4283", "kn529wc4372", "nn572km4370", "pt012cb4647", "qb957rw1430", "qk978vx9753", "qt854jh3199", "sc411ff4198", "td830rb1584",  "xf058ys1313", "yh093pt9555", "yt907db4998", "zp006sp7532"]
end

def default_hidden_druids
  return ["bb004bn8654"]
end

def collection_druids
  return ['wn860zc7322','kz071cg8658']
end

# the following must match what are in the users.yml fixtures
def user_login
  'user1'
end

def user2_login
  'user2'
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

def get_user(login)
  User.where(:username=>login).limit(1).first
end

def disable_user(login)
  user=get_user(login)
  user.active=false
  user.save
end

def register_new_user(username,password,email)
  visit new_user_registration_path
  fill_in 'register-email', :with=> email
  fill_in 'register-username', :with=> username
  fill_in 'user_password', :with=> password
  fill_in 'user_password_confirmation', :with=> password
end

def should_register_ok
   expect(current_path).to eq(root_path)
   expect(page).to have_content I18n.t('devise.registrations.signed_up_but_unconfirmed')
end

def login_as(login, password = nil)
  password ||= login_pw
  logout
  sign_in_link=I18n.t('revs.user.sign_in')
  has_link?(sign_in_link) ? click_link(sign_in_link) : visit(new_user_session_path)
  fill_in "user_login", :with => login
  fill_in "user_password", :with => password
  click_button 'submit'
end

def should_have_button(name)
  expect(page).to have_selector("input[type=submit][value='#{name}']")
end

def should_not_have_button(name)
  expect(page).not_to have_selector("input[type=submit][value='#{name}']")
end

def logout
  sign_out_button=I18n.t('revs.user.sign_out')
  if has_button?(sign_out_button)
    within('li.signout') do
      click_button(sign_out_button)
    end
  end
end

# some helper methods to do some quick checks

# Flagging history
def show_show_your_flagging_history(user_comment,curator_comment)
  expect(page).not_to have_content I18n.t('revs.flags.all_closed_flags')
  expect(page).to have_content I18n.t('revs.flags.your_closed_flags')
  expect(page).to have_content user_comment
  expect(page).to have_content curator_comment
end

# Flagging history
def show_not_show_flagging_history(user_comment,curator_comment)
  expect(page).not_to have_content I18n.t('revs.flags.all_closed_flags')
  expect(page).not_to have_content I18n.t('revs.flags.your_closed_flags')
  expect(page).not_to have_content user_comment
  expect(page).not_to have_content curator_comment
end

# Flagging history
def show_show_all_flagging_history(user_comment,curator_comment)
  expect(page).to have_content I18n.t('revs.flags.all_closed_flags')
  expect(page).not_to have_content I18n.t('revs.flags.your_closed_flags')
  expect(page).to have_content user_comment
  expect(page).to have_content curator_comment
end

# Annotations
def should_allow_annotations
  expect(page).to have_content(I18n.t('revs.annotations.add'))
end

def should_not_allow_annotations
  expect(page).not_to have_content(I18n.t('revs.annotations.add'))
end

# Flags
def should_allow_flagging
  expect(find('#flag-details-link')).to have_content(I18n.t('revs.flags.flag'))
  expect(page).not_to have_css('#flag-details-link.hidden')
end

def should_not_allow_flagging
  expect(find('#flag-details-link')).not_to have_content(I18n.t('revs.flags.flag'))
end

def should_deny_access(path)
  visit path
  expect(current_path).to eq(root_path)
  expect(page).to have_content(I18n.t('revs.messages.not_authorized'))
end

def should_deny_access_to_named_gallery(title)
  gallery=Gallery.where(:title=>title).first
  should_deny_access gallery_path(gallery)
end

def should_allow_access_to_named_gallery(title)
  gallery=Gallery.where(:title=>title).first
  visit gallery_path(gallery)
  expect(current_path).to eq(gallery_path(gallery))
  expect(page).to have_content title
end

def should_deny_access_for_beta(path)
  visit path
  expect(current_path).to eq(root_path)
  expect(page).to have_content('The Automotive Digital Library is currently in limited beta release.')
end

def should_allow_admin_section
  visit admin_dashboard_path
  expect(page).to have_content(I18n.t('revs.user.admin_dashboard'))
  expect(current_path).to eq(admin_dashboard_path)
end

def should_allow_curator_section
  visit curator_tasks_path
  expect(page).to have_content('Flagged Items')
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
  RestClient.post "#{Blacklight.default_index.connection.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
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

def review_flag(user, druid, content)
  login_as_user_and_goto_druid(user, druid)
  find_flag_by_content_and_click_button(content, @review_button)
end

def find_flag_by_content_and_click_button(content, button)
   get_a_flag_by_content(content).click_button(button)
end

def resolve_flag_wont_fix(user, druid, content, resolve_message,flag_id)
  login_as_user_and_goto_druid(user, druid)
  resolve_flag(content, resolve_message, @wont_fix_button,flag_id)
end

def resolve_flag_fix(user, druid, content, resolve_message,flag_id)
  login_as_user_and_goto_druid(user, druid)
  resolve_flag(content, resolve_message, @fix_button,flag_id)
end

def resolve_flag(content, resolve_message, button, flag_id)
  f = get_a_flag_by_content(content)
  within "\#edit_flag_#{flag_id}" do
    fill_in @resolution_field, :with=>resolve_message
    click_button button
  end
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

def create_flag(content)
  fill_in @comment_field, :with=>content
  sleep(1) # to prevent triggering spam bot preventor
  click_button @flag_button
end

def login_and_add_a_flag(user, druid, content)
  login_as_user_and_goto_druid(user,druid)
  create_flag(content)
end

def check_flag_was_created(user, druid, content, flag_count)
  # check the page for the correct messages
  check_page_for_flag(user, druid, content)

  #check the database for the comment and ensure the flag count was incremented
  return check_database_for_flag(user, flag_count, content)

end

def check_page_for_flag(user, druid, content)
  item_page=catalog_path(druid)
  expect(current_path).to eq(item_page)
  expect(page).to have_content(I18n.t('revs.flags.created'))
  expect(page).to have_content(content)
  expect(page).to have_button(@remove_button)
end

def check_database_for_flag(user, expected_total_flags, content)
  user=User.find_by_username(user)
  expect(Flag.count).to eq(expected_total_flags)
  flag=Flag.last
  expect(flag.comment).to eq(content)
  expect(flag.flag_type).to eq(@default_flag_type)
  flag.user=user
  return flag.id
end

def check_flag_was_deleted(user, druid, expected_total_flags)
  expect(page).to have_content(I18n.t('revs.flags.removed'))
  expect(Flag.count).to eq(expected_total_flags)
  expect(Flag.where(:user_id=>User.find_by_username(user).id,:druid=>druid).size).to eq(0)
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
  expect(page).to have_content(message)
  expect(Flag.count).to eq(expected_total_flags)

  #Make sure this flag isn't displaying since it has been resolved
  expect(get_a_flag_by_content(content)).to eq(nil)
end

def check_flag_resolution_in_db(content, resolution, state, id)
   flags = Flag.all
   for f in flags
     if(f.id == id)
       expect(f.state).to eq(state)
       f.resolution == resolution
     end
   end
end



def get_user_spam_count(username)
  return User.find_by_username(username).spam_flags
end

def has_content_array(all_content)
  all_content.each do |a|
    expect(page).to have_content(a)
  end
end

def has_no_content_array(all_content)
  all_content.each do |a|
    expect(page).to have_no_content(a)
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
  expect(page).to have_content(I18n.t('revs.search.search_results'))
  expect(page).to have_content('No entries found')  #TODO:  Figure out why not in /lib/locales/en.yml
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
  expect(current_path).to eq(item_path(druid))
end

def search_multiple_results(search, expected)
  pag_limit = 25 #Default for Kaminari
  visit search_path(:q=>'photo')
  expect(page).to have_content('Results')
  expect(page).to have_content("1 - #{expected} of #{expected}") if expected <= 25
  expect(page).to have_content("1 - #{expected} of #{25}") if expected > 25
  expect(page).to have_content('The David Nadig Collection of the Revs Institute')
  expect(page).to have_content('The John Dugdale Collection of the Revs Institute')
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

def get_title_from_druid(druid)
  return get_solrdoc_from_druid(druid)['title_tsi']
end

def get_solrdoc_from_druid(druid)
  return Blacklight.default_index.connection.select(:params =>{:q=>"id:#{druid}"})["response"]["docs"][0]
end

def cleanup_editstore_changes
  Editstore::Change.destroy_all
end
