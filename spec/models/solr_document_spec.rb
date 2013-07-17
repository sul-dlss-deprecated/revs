require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    doc.should be_a SolrDocument
    doc[:id].should == "12345"
    doc.should respond_to :export_formats
  end
  
  describe "collections" do
    it "should define themselves as such when they have the correct fields" do
      SolrDocument.new({:id=>"12345"}).is_collection?.should be_false
      SolrDocument.new({:id=>"12345", :format_ssim => "collection"}).is_collection?.should be_true
    end
    describe "collection siblings" do
      it "should memoize the solr request to get the siblings of a collection member" do
        response = {"response" => {"numFound" => 3, "docs" => [{:id=>"1234"}, {:id =>"4321"}]}}
        solr = mock("solr")
        solr.should_receive(:select).with(:params => {:fq => "is_member_of_ssim:\"collection-1\"", :sort=>"priority_isi desc",:rows => "20", :start=>"0"}).once.and_return(response)
        Blacklight.should_receive(:solr).and_return(solr)
        doc = SolrDocument.new({:id => "abc123", :is_member_of_ssim => ["collection-1"]})
        5.times do
          doc.collection_siblings
        end        
      end
    end
    describe "collection members" do
      it "should define themselves as such when they have the correct fields" do
        SolrDocument.new({:id => "12345"}).is_item?.should be_false
        SolrDocument.new({:"is_member_of_ssim" => "collection-1"}).is_item?.should be_true
      end
      it "should memoize the solr request to get collection members" do
        response = {"response" => {"numFound" => 3, "docs" => [{:id=>"1234"}, {:id =>"4321"}]}}
        solr = mock("solr")
        solr.should_receive(:select).with(:params => {:fq => "is_member_of_ssim:\"collection-1\"", :sort=>"priority_isi desc",:rows => "20",:start=>"0"}).once.and_return(response)
        Blacklight.should_receive(:solr).and_return(solr)
        doc = SolrDocument.new({:id => "collection-1", :format_ssim => "collection"})
        5.times do
          doc.collection_members
        end
      end
      it "should memoize the solr request to get a collection member's parent collection" do
        response = {"response" => {"numFound" => 1, "docs" => [{:id=>"1234"}]}}
        solr = mock("solr")
        solr.should_receive(:select).with(:params => {:fq => "id:\"abc123\""}).once.and_return(response)
        Blacklight.should_receive(:solr).and_return(solr)
        doc = SolrDocument.new({:id => "item-1", :is_member_of_ssim => ["abc123"]})
        5.times do
          doc.collection
        end
      end
      
      it "should return nil if the SolrDocument is not a collection" do
        SolrDocument.new(:id=>"1235").collection_members.should be nil
      end
    end

  end
  
  describe "images" do
    before(:all) do
      @images = SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images
    end
    it "should point to the test URL" do
      @images.each do |image|
        image.should include Revs::Application.config.stacks_url
      end
    end
    it "should link to the image identifier field " do
      @images.each do |image|
        image.should =~ /abc123|cba321/
      end
    end
    it "should have the proper default image dimension when no size is specified" do
      @images.each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:default]}/
      end
    end
    it "should return the requested dimentsion when one is specified" do
      SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images(:large).each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:large]}/
      end
    end
    it "should return nil when the document does not have an image identifier field" do
      SolrDocument.new(:id => "12345").images.should be nil
    end
    describe "image dimensions" do
      it "should be a hash of configurations" do
        SolrDocument.image_dimensions.should be_a Hash
        SolrDocument.image_dimensions.should have_key :default
      end
    end
  end
  
end