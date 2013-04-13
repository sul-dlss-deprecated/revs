require 'rest_client'

class Annotation < ActiveRecord::Base
  
  belongs_to :user  
  attr_accessible :text, :json, :user_id, :druid

  after_save :update_solr

    def update_solr

      id=self.druid
      text=self.text

      #RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "[{'id':'#{id}','annotations_tsim':{'add':'#{text}'}}]", :content_type => "application/json"
      
  #    curl 'localhost:8983/solr/dev/update?commit=true' -H 'Content-type:application/json' -d '[{"id":"wn860zc7322","annotations_tsim":{"add":"!!another annotation"}}]'
    end
    
end
