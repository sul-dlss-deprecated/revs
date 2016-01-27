class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
   self.default_processor_chain += [:phrase_search]

   # adjust the solr query by putting quotes around it if the user wants an exact phrase search
   def phrase_search(request_params)
     unless blacklight_params[:q].blank?
       case blacklight_params["search_match"]
         when "exact"
           request_params[:q] = "\"#{blacklight_params[:q]}\""
         when "all"
           request_params[:q] = blacklight_params[:q].split(' ').join(' AND ')
         else
           request_params[:q] = blacklight_params[:q]
       end
     end
   end

end
