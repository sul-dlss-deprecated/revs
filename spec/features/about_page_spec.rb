require 'spec_helper'

describe("About Pages",:type=>:request,:integration=>true) do
  
  before :each do
    @about_page_title=I18n.t("revs.about.project_title")
    @project_team_title=I18n.t("revs.about.team_title")
    @acknowledgements=I18n.t("revs.about.acknowledgements_title")
    @contact_us=I18n.t("revs.about.contact_title")
    @terms_of_use=I18n.t("revs.about.terms_of_use_title")
    @video_tutorials=I18n.t("revs.about.video_tutorials_title")
  end
  
  it "should show the about project page for various URLs" do
    visit '/about'
    expect(page).to have_content(@about_page_title)
    visit '/about/project'
    expect(page).to have_content(@about_page_title)    
    visit '/about/bogusness'
    expect(page).to have_content(@about_page_title)    
  end

  it "should detect a spammer as someone who submits the form too quickly" do
    visit contact_us_path
    expect(page).to have_content(@contact_us)
    fill_in 'message', :with=>'My annoying spam message'
    click_button 'Send'
    RevsMailer.stub_chain(:contact_message,:deliver).and_return('a mailer')
    expect(RevsMailer).not_to receive(:contact_message)
    expect(page).to have_content(I18n.t("revs.about.contact_message_spambot"))
    expect(current_path).to eq(root_path)
  end

  it "should detect a spammer as someone who fills in the hidden form field" do
    visit contact_us_path
    expect(page).to have_content(@contact_us)
    sleep 6.seconds
    fill_in 'message', :with=>'My annoying spam message'
    fill_in 'email_confirm', :with=>'hidden field'
    click_button 'Send'
    RevsMailer.stub_chain(:contact_message,:deliver).and_return('a mailer')
    expect(RevsMailer).not_to receive(:contact_message)
    expect(page).to have_content(I18n.t("revs.about.contact_message_spambot"))
    expect(current_path).to eq(root_path)
  end

  it "should show the contact us page" do
    visit contact_us_path
    expect(page).to have_content(@contact_us)
    sleep 6.seconds
    fill_in 'fullname', :with=>'Spongebob Squarepants'
    fill_in 'message', :with=>'I live in a pineapple under the sea.'
    RevsMailer.stub_chain(:contact_message,:deliver).and_return('a mailer')
    expect(RevsMailer).to receive(:contact_message)
    click_button 'Send'
    expect(page).to have_content(I18n.t("revs.about.contact_message_sent"))
  end

  it "should show the terms of use page" do
    visit '/about/terms_of_use'
    expect(page).to have_content(@terms_of_use)
  end

  it "should show the acknowledgements page" do
    visit '/about/acknowledgements'
    expect(page).to have_content(@acknowledgements)
  end

  it "should show the project team page" do
    visit '/about/team'
    expect(page).to have_content(@project_team_title)
  end

  it "should show the video tutorials page" do
    visit '/about/tutorials'
    expect(page).to have_content(@video_tutorials)
    # update link URL when Overview video is updated/replaced
    expect(page).to have_link(I18n.t("revs.help.videos.titles.overview"), href: "https://www.youtube.com/watch?v=rVBI_VCfWYg")
  end

end
