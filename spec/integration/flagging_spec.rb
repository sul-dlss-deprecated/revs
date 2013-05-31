require 'spec_helper'

describe("Flagging",:type=>:request,:integration=>true) do

  before :each do
    logout 
  end
    
  it "should allow multiple logged in users to flag an item, show all flags, and then allow the user remove the flag" do
      
      remove_button='Remove Flag'
      flag_button='Flag Item'
      comment_field='flag_comment'
      default_flag_type='error'
      druid='qb957rw1430'
      initial_flag_count=Flag.count
            
      # login and visit an item as a regular user
      login_as(user_login)
      user_comment='all wrong!'
      item_page=catalog_path(druid)

      #flag the item
      visit item_page
      fill_in comment_field, :with=>user_comment
      click_button flag_button
      
      # check the page for the correct messages
      current_path.should == item_page
      page.should have_content('The item was flagged.')
      page.should have_content('This item has been flagged 1 time.')
      page.should have_content("You flagged it on #{ApplicationController.new.show_as_date(Date.today)} with this comment: #{user_comment}")
      page.should have_button(remove_button)
      
      # check the database
      user=User.find_by_username(user_login)
      Flag.count.should == initial_flag_count + 1
      flag=Flag.last
      flag.comment.should == user_comment
      flag.flag_type.should == default_flag_type
      flag.user=user

      # login and visit an item as a curator
      logout
      login_as(curator_login)
      curator_comment='not so bad'

      #flag the item
      visit item_page
      fill_in comment_field, :with=>curator_comment
      click_button flag_button
      
      # check the page for the correct messages
      current_path.should == item_page
      page.should have_content('The item was flagged.')
      page.should have_content('This item has been flagged 2 times.')
      page.should have_content("You flagged it on #{ApplicationController.new.show_as_date(Date.today)} with this comment: #{curator_comment}")
      page.should have_content("#{user.full_name} flagged it on #{ApplicationController.new.show_as_date(Date.today)} with this comment: #{user_comment}")
      page.should have_button(remove_button)
      
      # check the database
      curator=User.find_by_username(curator_login)
      Flag.count.should == initial_flag_count + 2
      flag=Flag.last
      flag.comment.should == curator_comment
      flag.flag_type.should == default_flag_type
      flag.user=curator
           
      # remove and confirm deletion of the curator's flag in the database
      click_button remove_button
      page.should have_content('The flag was removed.')
      Flag.count.should == initial_flag_count + 1
      Flag.last.user.should == user
           
    end
    
end