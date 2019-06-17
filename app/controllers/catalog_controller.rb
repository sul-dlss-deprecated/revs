# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Blacklight::Catalog

  before_filter :ajax_only, :only=>[:update_carousel,:show_collection_members_grid, :notice_dismissed]

  before_filter :filter_params
  before_filter :add_facets_for_curators
  before_filter :set_default_image_visibility_query

  # custom archive facet query which excludes collections
  def self.archives_query
    opts={}
    SolrDocument.archives.each_with_index {|archive,index| opts["archive_#{index}"]={:label=>archive,:fq=>"archive_ssi:\"#{archive}\" AND -format_ssim:\"collection\""} }
    opts
  end

  # delete editing form parameters when there is a get request so they don't get picked up and carried to all links by Blacklight
  def filter_params
    if request.get?
      params.delete(:bulk_edit)
      params.delete(:authenticity_token)
    end
  end

    # google and other bots continue to use old facet values for the timestamp facet when indexing ... this in turn causes a 500 exception deep within blacklight, triggering excessive logging; just tell them to get lost instead   Peter Mangiafico, October 5 2015  ... # this is fixed in later versions of blacklight
    # also check for end ranges before beginning ranges
  def bad_facet_params

    return false unless params

    return true if params[:f] && params[:f][:timestamp] && ((blacklight_config.facet_fields['timestamp'].query.keys + params[:f][:timestamp]).uniq.size) != blacklight_config.facet_fields['timestamp'].query.keys.size

    return true if params[:range] && params[:range][:pub_year_isim] && ((params[:range][:pub_year_isim][:end].to_i - params[:range][:pub_year_isim][:begin].to_i) < 0)

    return true if is_integer?(params[:page]) == false  # page param is not nil and also not an integer can cause problems

    return true if is_integer?(params["facet.page"]) == false  # page param is not nil and also not an integer can cause problems

    return true if is_integer?(params[:per_page]) == false # per_page param is not nil and also not an integer can cause problems

    return true if params[:per_page] == "0" # per_page param is 0

  end

  def add_facets_for_curators
    if can? :curate, :all
      self.blacklight_config.add_facet_field 'has_more_metadata_ssi', :label => "More Metadata"
      self.blacklight_config.add_facet_field 'visibility_isi', :label => 'Visibility', :query => {:visibility_1=>{:label=>"Hidden", :fq=>"visibility_isi:0"}}
      self.blacklight_config.add_sort_field 'score_isi asc, score desc, title_tsi asc', :label => 'metadata score'
    end
  end

  def index

    not_authorized if params[:view]=='curator' && cannot?(:bulk_update_metadata,:all)

    if on_home_page || @force_render_home # on the home page

      not_authorized unless can? :read,:home_page

      unless fragment_exist?("home") # fragment cache for performance

        @highlight_collections=SolrDocument.highlighted_collections
        @random_collection_number=Random.new.rand(@highlight_collections.size) # pick a random one to start with for non-JS users
        @highlighted_galleries=Gallery.featured.limit(4)

      end

    elsif can?(:bulk_update_metadata,:all) && params[:bulk_edit] && request.post? && Revs::Application.config.disable_editing == false # user submitted a bulk update operation and has the rights to do it

      not_authorized unless can?(:bulk_update_metadata,:all)

      @bulk_edit=params[:bulk_edit]

      if @bulk_edit[:attribute].blank? || @bulk_edit[:selected_druids].blank? || (invalid_entry?(@bulk_edit[:new_value]) && @bulk_edit[:action] == 'update') || ((invalid_entry?(@bulk_edit[:new_value]) || invalid_entry?(@bulk_edit[:search_value])) && @bulk_edit[:action] == 'replace')
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

    if bad_facet_params
      session[:search]=nil # blow away the search context
      routing_error
      return
    end

    search_params_logic << :phrase_search # add phrase searching capability (defined in lib/revs_search_builder)

    super

    if @response['response']['docs'].nil? # nothing
      routing_error
      return
    else
    # if we get this far, it may have been a search operation, so if we only have one search result, just go directly there
     if (@response['response']['numFound'] == 1 && @response['response']['docs'].size > 0 && can?(:read,:item_pages))
       redirect_to item_path(@response['response']['docs'].first['id'])
       return
     end
    end

    flash.now[:notice]=t('revs.messages.search_affected') if (Revs::Application.config.search_results_affected && !params[:q].nil? && !(on_home_page || @force_render_home))

  end

  def show

    unless can? :read,:item_pages
      not_authorized(:replace_message=>t('revs.messages.in_beta_not_authorized_html'))
      return
    else
      super
      if (@document.visibility == :hidden && cannot?(:view_hidden, SolrDocument)) || (@document.is_collection? && !@document.visible_items_in_collection? && cannot?(:view_hidden, SolrDocument))
        not_authorized
        return
      end
    end

    if from_gallery? # if we are coming from a gallery link, grab the gallery and items to show at the bottom of the page
      @galleries=Gallery.where(:id=>params[:gallery_id])
      if @galleries.size != 1 # we should only have one, otherwise something is wrong
        not_authorized
        return
      end
      @gallery=@galleries.first
      if cannot? :read, @gallery  # we should not see the gallery items in the grid at the bottom of the page if we don't have permission to
         not_authorized
         return
      end
      @saved_items=@gallery.saved_items(current_user).limit(CatalogController.blacklight_config.collection_member_grid_items)
    end

  end

  # an ajax call to show just the collection members grid at the bottom of the page
  # when logged in as a curator on the item detail page, sort by metadata score, otherwise randomly
  # collection landing pages will always have a random selection
  # in all cases, do not show hidden images
  def show_collection_members_grid
    @document = SolrDocument.find(params[:id])
    if params[:on_page] == 'item'
      sort = (user_signed_in? && current_user.curator?) ? "score" : "random"
      @collection_members=@document.siblings(:sort=>sort,:include_hidden=>false)
      @type=:siblings
      @show_full_width=true
    else
      @collection_members=@document.collection_members(:sort=>"priority",:include_hidden=>false)
      @type=:collection
      @show_full_width=false
    end
  end

  # an ajax call from metadata edit form for fields that allow autocomplete
  def autocomplete
    result=Ontology.terms(params[:field],params[:term]).map {|term| term.value }
     respond_to do |format|
      format.html { routing_error }
      format.json { render :json=>result.to_json }
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

  # an ajax only call that sets a session variable indicating the user has dismissed the site warning message
  def notice_dismissed
    session[:notice_dismissed]=true
    render :nothing=>true
  end

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed... overriding default blacklight behavior
  def invalid_document_id_error
    routing_error
  end

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params

    config.advanced_search = {
      :qt => 'standard'
    }

    config.default_solr_params = {
      :qt => 'standard',
      :facet => 'true',
      :rows => 20,
      :fl => "*",
      :"facet.mincount" => 1,
      :echoParams => "all"
    }

    config.document_solr_request_handler = nil
    config.document_solr_path = 'get'
    config.document_unique_id_param = :ids


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

    # add the phrase searching capability (defined in the lib folder)
    config.search_builder_class = RevsSearchBuilder

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {}
    #  :qt => 'standard',
    #  :fl => '*',
    #  :rows => 1,
    #  :q => '{!raw f=id v=$id}'
    # }

    # Define our results views.
    # These are in "_document_gallery", "document_detailed", etc.
    config.view = {:gallery => {}, :detailed => {}, :curator => {} }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tsi'
    config.index.display_type_field = 'format_ssim'

    # solr field configuration for document/show views
    config.show.title_field  = 'title_tsi'
    config.show.display_type_field = 'format_ssim'


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
    config.add_facet_field 'pub_year_isim', :label => 'Year', :sort => 'index', :limit => 25, :range => true
  #  config.add_facet_field 'format_ssim', :label => 'Format'
    config.add_facet_field 'marque_ssim', :label => 'Marque', :limit => 25, :index_pagination=>true
    config.add_facet_field 'model_year_ssim', :label => 'Model Year', :sort => 'index', :limit => 25
    config.add_facet_field 'model_ssim', :label => 'Model', :limit => 25, :index_pagination=>true
    config.add_facet_field 'archive_ssim', :label => "Archive", :query => archives_query
    config.add_facet_field 'collection_ssim', :label => "Collection"
    config.add_facet_field 'photographer_ssi', :label => "Photographer", :limit => 25, :index_pagination=>true
    config.add_facet_field 'entrant_ssim', :label => "Entrant", :limit => 25, :index_pagination=>true
    config.add_facet_field 'people_ssim', :label => "People", :limit => 25, :index_pagination=>true
    config.add_facet_field 'venue_ssi', :label => "Venue", :limit => 25, :index_pagination=>true
    config.add_facet_field 'event_ssi', :label => "Event", :limit => 25, :index_pagination=>true
    config.add_facet_field 'group_ssim', :label => "Group", :limit => 25, :index_pagination=>true

    config.add_facet_field 'timestamp', :label => 'Added recently', :query => {
       :weeks_1 => { :label => 'within last week', :fq => "timestamp:[\"#{show_as_timestamp(1.week.ago)}\" TO *]" },
       :months_1 => { :label => 'within last month', :fq => "timestamp:[\"#{show_as_timestamp(1.month.ago)}\" TO *]" },
       :months_6 => { :label => 'within last six months', :fq => "timestamp:[\"#{show_as_timestamp(6.months.ago)}\" TO *]" }
    }

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

    config.add_search_field 'title_tsi', :label => 'Title'
		config.add_search_field 'description_tsim', :label => 'Description'
		config.add_search_field 'annotations_tsim', :label => 'Annotations'
		config.add_search_field 'source_id_ssi', :label => 'Source ID'
		config.add_search_field 'marque_tim', :label => 'Marque'
		config.add_search_field 'group_class_tsi', :label => 'Group or Class'
		config.add_search_field 'model_tim', :label => 'Model'
		config.add_search_field 'model_year_tim', :label => 'Model Year'
    config.add_search_field 'vehicle_markings_tsi', :label => 'Vehicle Markings'
		config.add_search_field 'people_tim', :label => 'People'
		config.add_search_field 'entrant_tim', :label => 'Entrant'
		config.add_search_field 'current_owner_ti', :label => 'Current Owner'
		config.add_search_field 'venue_ti', :label => 'Venue'
		config.add_search_field 'track_ti', :label => 'Track'
		config.add_search_field 'event_ti', :label => 'Event'
		config.add_search_field 'cities_ti', :label => 'City'
		config.add_search_field 'countries_ti', :label => 'Country'
		config.add_search_field 'states_ti', :label => 'State'
		config.add_search_field 'photographer_ti', :label => 'Photographer'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'title', :field => 'score desc, title_tsi desc, source_id_ssi asc', :label => 'title'
    config.add_sort_field 'identifier', :field => 'source_id_ssi asc, score desc, title_tsi desc', :label => 'identifier'
    config.add_sort_field 'year', :field => 'pub_year_single_isi asc, score desc, title_tsi asc', :label => 'year'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # displays values and pagination links for a single facet field
  # overridden from base blacklight so we can add facet index pagination links
  def facet
    extra_controller_params = (params[:"facet.prefix"] ? {"facet.prefix"=>params[:"facet.prefix"]} : {})

    if bad_facet_params
      session[:search]=nil # blow away the search context
      routing_error
      return
    end

    @facet = blacklight_config.facet_fields[params[:id]]
    @response = get_facet_field_response(@facet.key, params,extra_controller_params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)


    respond_to do |format|
      # Draw the facet selector for users who have javascript disabled:
      format.html
      format.json { render json: render_facet_list_as_json }

      # Draw the partial for the "more" facet modal window:
      format.js { render :layout => false }
    end
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
        email.deliver_now
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

  private
  def invalid_entry?(str)
    str.blank? || str.length < 2
  end

end
