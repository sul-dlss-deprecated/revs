# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog

  before_filter :ajax_only, :only=>[:update_carousel,:show_collection_members_grid]
  
  before_filter :filter_params
  before_filter :add_facets_for_curators
  before_filter :set_default_image_visibility_query
  
  # delete editing form parameters when there is a get request so they don't get picked up and carried to all links by Blacklight
  def filter_params
    if request.get?
      params.delete(:bulk_edit) 
      params.delete(:authenticity_token)
    end
  end
  
  def add_facets_for_curators
    if can? :curate, :all
      self.blacklight_config.add_facet_field 'has_more_metadata_ssi', :label => "More Metadata"
      self.blacklight_config.add_facet_field 'visibility_isi', :label => 'Visibility', :query => {:visibility_1=>{:label=>"Hidden", :fq=>"visibility_isi:0"}}
    end
  end
  
  def index
    
    not_authorized if params[:view]=='curator' && cannot?(:bulk_update_metadata,:all)
    
    if on_home_page || @force_render_home # on the home page
        
      not_authorized unless can? :read,:home_page
      
      unless fragment_exist?('home') # fragment cache for performance

        @highlight_collections=SolrDocument.highlighted_collections
        @random_collection_number=Random.new.rand(@highlight_collections.size) # pick a random one to start with for non-JS users
      
        # get some information about all the collections and images we have so we can report on total numbers
        @total_collections=SolrDocument.all_collections.size
        if can?(:view_hidden, SolrDocument)
          @total_images=SolrDocument.total_images(:all)
          @total_hidden_images=SolrDocument.total_images(:hidden)
        else
          @total_images=SolrDocument.total_images
        end
        
      end
    
    elsif can?(:bulk_update_metadata,:all) && params[:bulk_edit] && request.post? # user submitted a bulk update operation and has the rights to do it

      not_authorized unless can?(:bulk_update_metadata,:all)
      
      @bulk_edit=params[:bulk_edit]
            
      if @bulk_edit[:attribute].blank? || @bulk_edit[:new_value].blank? || @bulk_edit[:selected_druids].blank?
        flash.now[:error]=t('revs.messages.bulk_update_instructions')
      else
        success=SolrDocument.bulk_update(@bulk_edit,current_user)
        if success
          flash.now[:notice]=t('revs.messages.saved') if ['staging','development'].include?(Rails.env)
        else
          flash.now[:error]=t('revs.messages.validation_error')
        end
      end

    else

       not_authorized(:replace_message=>t('revs.messages.in_beta_not_authorized_html')) unless can? :read,:search_pages
 
    end
    
    super
        
    # if we get this far, it may have been a search operation, so if we only have one search result, just go directly there
    redirect_to item_path(@response['response']['docs'].first['id']) if (@response['response']['numFound'] == 1 && can?(:read,:item_pages))

  end
  
  def show
    
    not_authorized(:replace_message=>t('revs.messages.in_beta_not_authorized_html')) unless can? :read,:item_pages
    
    super

    not_authorized if @document.visibility == :hidden && cannot?(:view_hidden, SolrDocument)
    
  end
  
  # an ajax call to show just the collection members grid at the bottom of the page
  def show_collection_members_grid
    @document=SolrDocument.find(params[:id])
    if params[:on_page] == 'item'
      @collection_members=@document.siblings(:random=>true,:include_hidden=>can?(:view_hidden, SolrDocument))
      @type=:siblings
      @show_full_width=true
    else
      @collection_members=@document.collection_members(:include_hidden=>can?(:view_hidden, SolrDocument))
      @type=:collection
      @show_full_width=false     
    end
  end
  
  # an ajax call to get the next set of images to show in a carousel on the collection detail page
  def update_carousel
    druid=params[:druid]
    @rows=params[:rows] || blacklight_config.collection_member_carousel_items
    @start=params[:start] || 0
    @document = SolrDocument.find(druid)
    @carousel_members = @document.get_members(:rows=>@rows,:start=>@start,:include_hidden=>can?(:view_hidden, SolrDocument))
  end

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed... overriding default blacklight behavior to get our home page to work
  def invalid_solr_id_error
    @force_render_home=true
    super
  end
      
  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
   
    config.default_solr_params = { 
      :qt => 'standard',
      :facet => 'true',
      :rows => 10,
      :fl => "*",
      :"facet.mincount" => 1,
      :echoParams => "all"
    }
    
    
    # various Revs specific collection field configurations
    
    # needs to be stored so we can retreive it
    # needs to be in field list for all request handlers so we can identify collections in the search results.
    config.collection_identifying_field = "format_ssim"
    config.collection_identifying_value = "collection"
    
    # needs to be indexed so we can search it to return relationships.
    # needs to be in field list for all request handlers so we can identify collection members in the search results.
    config.collection_member_identifying_field = "is_member_of_ssim"
    
    # needs to be stored so we can retreive it for display
    # needs to be in field list for all request handlers
    config.collection_member_collection_title_field = "collection_ssim"
    
    config.collection_member_grid_items = 20
    config.collection_member_carousel_items = 5
    
    # needs to be sotred so we can retreive it
    # needs to be in field list for all request handlers so we can get images the document anywhere in the app.
    config.image_identifier_field = "image_id_ssm"

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
     :qt => 'standard',
     :fl => '*',
     :rows => 1,
     :q => '{!raw f=id v=$id}' 
    }
    
    # tentatively removed 'brief' view type
    config.document_index_view_types = ["gallery","detailed","curator"]

    # solr field configuration for search results/index views
    config.index.show_link = 'title_tsi'
    config.index.record_display_type = 'format_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'title_tsi'
    config.show.heading = 'title_tsi'
    config.show.display_type = 'format_ssim'
    

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'pub_year_isim', :label => 'Year', :sort => 'index'
    config.add_facet_field 'format_ssim', :label => 'Format'
    config.add_facet_field 'marque_ssim', :label => 'Marque'
    config.add_facet_field 'model_year_ssim', :label => 'Model Year'
    config.add_facet_field 'model_ssim', :label => 'Model'
    config.add_facet_field 'collection_ssim', :label => "Collection"
    
    # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    # }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    config.add_index_field 'pub_year_isim', :label => 'Year:'
    config.add_index_field 'format_ssim', :label => 'Format:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'pub_year_isim', :label => 'Year:'
    config.add_show_field 'format_ssim', :label => 'Format:'
    config.add_show_field 'description_tsim', :label => 'Description:'
    config.add_show_field 'source_id_ssi', :label => "Identifier:"
    config.add_show_field 'collection_ssim', :label => "Collection:"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    config.add_search_field 'all_fields', :label => 'All Fields'
    

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
    
    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = { 
        :qf => '$author_qf',
        :pf => '$author_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    #config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    #config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'
    config.add_sort_field 'title_tsi desc, source_id_ssi asc', :label => 'title'
    config.add_sort_field 'source_id_ssi asc, title_tsi desc', :label => 'identifier'
    config.add_sort_field 'pub_year_single_isi asc, title_tsi asc', :label => 'year'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email
    @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    if request.post?
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
        
        if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
          email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message]}, url_gen_params)
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      unless flash[:error]
        email.deliver 
        flash[:success] = t('revs.about.contact_message_sent')
        if request.xhr?
          render :email_sent, :formats => [:js]
          return
        else
          redirect_to catalog_path(params['id']) 
        end
      end
    end

    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
  end

end 
