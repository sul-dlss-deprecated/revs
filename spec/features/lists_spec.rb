require "rails_helper"

describe("Lists",:type=>:request,:integration=>true) do

  it "should only show public active saved queries when not logged in" do
    visit lists_path
    expect(page).to have_content "Public query"
    expect(page).to_not have_content "Curators query"
    expect(page).to_not have_content "Inactive query"
  end

  it "should show all active saved queries when logged in as a curator or admin" do
    [admin_login,curator_login].each do |test_user|
       login_as(test_user)
       visit lists_path
       expect(page).to have_content "Public query"
       expect(page).to have_content "Curators query"
       expect(page).to_not have_content "Inactive query"
     end
  end

  it "should redirect to home page if there are no saved queries visible" do
    SavedQuery.where(:active=>true).where(:visibility=>'public').each {|s| s.update_attribute(:active,false)}
    visit lists_path
    expect(current_path).to eq(root_path)
  end
  
end
