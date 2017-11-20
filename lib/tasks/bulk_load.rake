# encoding: UTF-8

require 'rest_client'
require 'csv'
require 'countries'
require 'pathname'
require 'revs-utils'
require 'nokogiri'
$stdout.sync = true

namespace :revs do
  @sourceid = 'sourceid'
  @visibility= 'hide'
  @seperator = '|'
  @filename = 'filename'
  @csv_extension_wild = '*.csv'
  @csv_extension = ".csv"
  @log_extension = ".out" #use something beside .log to avoid the autorotate feature for .log files
  @success = "SUCCESS:"
  @failure = "FAILURE:"
  @assigner = "="
  @mvf = "_mvf"
  @max_expected_collection_size = 2147483647
  @id = "id"

  desc "Re-save all solr docs - useful for adding the score or other data that is added on save"
  #Run Me: RAILS_ENV=production bundle exec rake revs:save_all_solr_docs collection="John Dugdale Collection" # optiontally limited to a collection
  #Run Me: RAILS_ENV=production bundle exec rake revs:save_all_solr_docs limit=100 # optionally sets a limit of number of items
  #Run Me: RAILS_ENV=production nohup bundle exec rake revs:save_all_solr_docs > save_all_docs.log 2>&1& # nohup mode with logged output
  #Run Me: RAILS_ENV=production bundle exec rake revs:save_all_solr_docs zero_score_only=true limit=100 # optionally tells it to save only documents with a score of 0
  #Run Me: RAILS_ENV=production bundle exec rake revs:save_all_solr_docs collection="John Dugdale Collection" update_collection_name=true # fix the collection name in all of the items in a given collection by grabbing the name from the collection object and updating it in the items, NOTE if no collection name needs to be updated, the object may not be saved if there are no other updates (like score)

  task :save_all_solr_docs  => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    collection = ENV['collection'] || '' # if passed, limits to this collection only
    rerun = ENV['rerun'] || '' # if passed as a filename, will try to just resave any errored out druids
    zero_score_only = ENV['zero_score_only'] || "" # if passed in, then only those with a score of 0 will be resaved
    update_collection_name = ENV['update_collection_name'] || "" # if passed in, will update the collection name in the item with the name from the collection object, useful if the name has changed

    q="*:*"
    q+=" AND collection_ssim:\"#{collection}\"" unless collection.blank?
    q+=" AND score_isi:0" unless zero_score_only.blank?

    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :fl=>'id', :rows=>rows})
    total_docs=@all_docs['response']['docs'].size

    start_time=Time.now
    n=0
    num_errors=0
    collection_names={}

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}" unless collection.blank?
    puts " limited to #{limit} items" unless limit.blank?
    puts " limited to only those docs with a score of 0" unless zero_score_only.blank?
    puts " fixing collection name" unless update_collection_name.blank?
    puts " found #{total_docs} items"

    puts ""
    puts q
    puts ""

    @all_docs['response']['docs'].each do |doc|

      id=doc['id']
      n+=1
      puts "#{n} of #{total_docs}: #{id}"
       begin
         s=SolrDocument.find(id)
         if update_collection_name && !s.is_collection? # grab and cache the collection name if needed and update in the object
           collection_names[s.collections.first] ||= RevsUtils.clean_collection_name(s.collection.title)
           s.collection_names=collection_names[s.collections.first] # update collection name
         else
           s.timestamp=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
           s.resaved_at=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ') # write out a new timestamp to be sure we have at least one update for solr to write the doc out
        end
       result = s.save(:commit=>false,:no_update_db=>true) # do not autocommit when in batch mode, allow the config to decide when to commit
       unless result
          puts " *** ERROR, SAVE RETURNED FALSE: #{id}"
          num_errors+=1
       end
       rescue
         puts " *** ERROR: #{id}"
         num_errors+=1
       end
    end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} saved, #{num_errors} errors"
    puts ""

    SolrDocument.new.send_commit

  end

  desc "Re-save errored solr docs - load a log file from the 'save_all_solr_docs' tasks and re-save errored out druids"
  #Run Me: RAILS_ENV=production bundle exec rake revs:save_all_solr_docs file=save_all_docs.log # load a logged output file and just resave error out
  task :resave_docs  => :environment do |t, args|

    file_path = ENV['file'] || '' # log file

    raise 'no file passed' if (file_path.blank? || !File.exists?(file_path))

    start_time=Time.now
    n=0
    num_errors=0

    puts ""
    puts "Started at #{start_time}"
    puts ""

    IO.readlines(file_path).each do |line|

      downcased_line=line.downcase

      if downcased_line.include? 'error'
        id=downcased_line.scan(/[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]/).first
        if id
          n+=1
          puts "#{n}: #{id}"
           begin
             s=SolrDocument.find(id)
             s.timestamp=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ') # write out a new timestamp to be sure we have at least one update for solr to write the doc out
             result = s.save(:commit=>false,:no_update_db=>true) # do not autocommit when in batch mode, allow the config to decide when to commit
             unless result
                puts " *** ERROR, SAVE RETURNED FALSE: #{id}"
                num_errors+=1
             end
           rescue
             puts " *** ERROR: #{id}"
             num_errors+=1
           end
         end
     end

    end

    end_time=Time.now

    SolrDocument.new.send_commit

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{n} saved, #{num_errors} errors"
    puts ""

  end


  desc "Touch all solr docs (but not update them) - useful when synonym file or config has changed"
  #Run Me: RAILS_ENV=production rake revs:touch_solr_docs collection="John Dugdale Collection" # optionally limited to a collection
  #Run Me: RAILS_ENV=production rake revs:touch_solr_docs limit=100 # optionally sets a limit of number of items
  task :touch_solr_docs  => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    collection = ENV['collection'] || '' # if passed, limits to this collection only

    q="*:*"
    q+=" AND collection_ssim:\"#{collection}\"" unless collection.blank?
    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>rows})
    total_docs=@all_docs['response']['docs'].size

    start_time=Time.now
    n=0
    num_errors=0

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}" unless collection.blank?
    puts " limited to #{limit} items" unless limit.blank?
    puts ""

    @all_docs['response']['docs'].each do |doc|

      id=doc['id']
      n+=1
      puts "#{n} of #{total_docs}: #{id}"
      begin
        url="#{Blacklight.default_index.connection.options[:url]}/update"
        params={:add=>{:doc=>doc}}.to_json
        RestClient.post url, params,:content_type => :json, :accept=>:json
      rescue
        puts " *** ERROR: #{id}"
        num_errors+=1
      end
  end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} touched, #{num_errors} errors"
    puts ""

  end

  desc "Update/add title to each item model record associated with Flags, Annotations and Saved Items - should only need to be run once after migration adding title to item model"
  #Run Me: RAILS_ENV=production rake revs:update_item_title verbose=true
  task :update_item_title => :environment do |t, args|

    verbose = ENV['verbose'] || false

    flags=Flag.all
    annotations=Annotation.all
    saved_items=SavedItem.all

    [flags,annotations,saved_items].each do |models|
      total=models.count
      puts "Updating #{total} #{models.first.class.name.downcase}s" if verbose
      n=0
      models.each do |model|
          n+=1
          puts "#{n} of #{total} : #{model.druid}" if verbose
          solr_doc=model.solr_document
          solr_doc.update_item if solr_doc
       end
    end

  end

  desc "Add source id to various model records that have druids -- should only need to be run once"
  #Run Me: RAILS_ENV=production nohup bundle exec rake revs:add_source_id &
  task :add_source_id => :environment do |t, args|

    puts "Started at #{Time.now}"
    count_flag = success_flag = error_flag = 0
    count_annotation = success_annotation = error_annotation = 0
    count_saved_item = success_saved_item = error_saved_item = 0
    count_item = success_item = error_item = 0

    puts "Updating flags..."
    Flag.find_each do |flag|
      count_flag += 1
      begin
        flag.update_attributes(:source_id => flag.solr_document['source_id_ssi'])
        success_flag += 1
      rescue => e
        error_flag +=1
        puts "*** ERROR ON flag #{flag.id} - #{e.message}"
      end
    end

    puts "Updating annotations..."
    Annotation.find_each do |annotation|
      count_annotation += 1
      begin
        annotation.update_attributes(:source_id => annotation.solr_document['source_id_ssi'])
        success_annotation += 1
      rescue => e
        error_annotation +=1
        puts "*** ERROR ON annotation #{annotation.id} - #{e.message}"
      end
    end

    puts "Updating saved_items..."
    SavedItem.find_each do |saved_item|
      count_saved_item += 1
      begin
        saved_item.update_attributes(:source_id => saved_item.solr_document['source_id_ssi'])
        success_saved_item += 1
      rescue => e
        error_saved_item +=1
        puts "*** ERROR ON saved_item #{saved_item.id} - #{e.message}"
      end
    end

    puts "Updating items..."
    Item.find_each do |item|
      count_item += 1
      begin
        item.update_attributes(:source_id => item.solr_document['source_id_ssi'])
        success_item += 1
      rescue => e
        error_item +=1
        puts "*** ERROR ON item #{item.id} - #{e.message}"
      end
    end

    puts "Successful flags: #{success_flag}.  Errored flags: #{error_flag}.  Total flags: #{count_flag}."
    puts "Successful annotations: #{success_annotation}.  Errored annotations: #{error_annotation}.  Total annotations: #{count_annotation}."
    puts "Successful saved items: #{success_saved_item}.  Errored saved items: #{error_saved_item}.  Total saved items: #{count_saved_item}."
    puts "Successful items: #{success_item}.  Errored items: #{error_item}.  Total items: #{count_item}."
    puts "Ended at #{Time.now}"

  end

  desc "Batch update a single specified field with a single specified value based on results from a supplied query -- if the field to update is multivalued, you MUST also provide an old value to search for to avoid replacing the entire field"
  #Run Me: RAILS_ENV=production rake revs:bulk_update_field solr_query='photographer_ssi:"Rudolfo Mailander"' field_to_update="photographer" new_value="Rodolfo Mailander" collection="John Dugdale Collection" # limited to a collection
  #Run Me: RAILS_ENV=production rake revs:bulk_update_field solr_query='photographer_ssi:"Rudolfo Mailander"' field_to_update="photographer" new_value="Rodolfo Mailander" dry_run=true # dry run, no updates
  #Run Me: RAILS_ENV=production rake revs:bulk_update_field solr_query='photographer_ssi:"Rudolfo Mailander"' field_to_update="photographer" new_value="Rodolfo Mailander" limit=100 # sets a limit of number of items
  #Run Me: RAILS_ENV=production rake revs:bulk_update_field solr_query='photographer_ssi:"Rudolfo Mailander"' field_to_update="photographer" new_value="Rodolfo Mailander" old_value="Rudolfo Mailander" # ensure that only entries with this old value are replaced (essential for mulivalued fields)
  # you can mix and match those parameters
  task :bulk_update_field => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    dry_run = ENV['dry_run'] || false # if passed, no updates are sent to editstore
    collection = ENV['collection'] || '' # if passed, limits to this collection only
    field_to_update= ENV['field_to_update']
    new_value= ENV['new_value']
    old_value= ENV['old_value'] || ''
    solr_query= ENV['solr_query']

    raise "**** Need to supply the field to update, the new value, and the docs to search for" if field_to_update.blank? || new_value.blank? || solr_query.blank?

    num_updated=0
    num_not_sent=0
    num_errors=0

    start_time=Time.now

    q=solr_query
    q+=" AND collection_ssim:\"#{collection}\"" unless collection.blank?
    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>rows})

    total_docs=@all_docs['response']['docs'].size
    n=0

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned from query #{solr_query}"
    puts " limited to collection: #{collection}" unless collection.blank?
    puts " limited to #{limit} items" unless limit.blank?
    puts " dry run" if dry_run
    puts " field to update: #{field_to_update}"
    puts " new value to set: #{new_value}"
    puts " old value: #{old_value}"
    puts " found #{total_docs} items"

    puts "solr: #{Blacklight.default_index.connection.options[:url]}"
    puts "editstore enabled: #{Revs::Application.config.use_editstore}"
    puts "***********WARNING: Editstore is not enabled" unless Revs::Application.config.use_editstore
    puts ""

    @all_docs['response']['docs'].each do |doc|

      n+=1

    begin

        unless dry_run # if we are not a dry run
          item=SolrDocument.new(doc)
          if old_value.blank? # no old value specified, just update the field
            item.send("#{field_to_update}=",new_value)
          else # old value was specified, see if this is a multivalued field that needs a pinpoint update
            current_values = item.send(field_to_update)
            if current_values.class == Array # it is multivalued!
              updated_values = current_values.map {|element| (element == old_value) ? new_value : element } # replace the old value with the new value in the array
              item.send("#{field_to_update}=",updated_values)
            else # it is not multivalued, update it if it matches
              item.send("#{field_to_update}=",new_value) if current_values == old_value
            end
          end
          if item.unsaved_edits.blank? # no changes
            puts "...Skipping #{doc['id']}"
            num_not_sent+=1
          else
            result=item.save
            if result
              puts "...Updated #{doc['id']}"
              num_updated+=1
            else
              puts "...***FAILED TO SAVE #{doc['id']}"
              num_errors+=1
            end
          end
        else
          puts "...Dry run for #{doc['id']}"
          num_not_sent+=1
        end

      rescue
        num_errors+=1
        puts "...ERROR #{doc['id']}!"
      end

    end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} checked, #{num_errors} errors, #{num_updated} updated, #{num_not_sent} updates not sent (dry run or no changes needed)"
    puts ""

  end

  desc "Apply missing dates in MODs from solr documents - fixing previous bug where dates were not making it to editstore"
  #Run Me: RAILS_ENV=production rake revs:fix_missing_dates collection="John Dugdale Collection" # limited to a collection
  #Run Me: RAILS_ENV=production rake revs:fix_missing_dates dry_run=true # dry run, no updates
  #Run Me: RAILS_ENV=production rake revs:fix_missing_dates limit=100 # sets a limit of number of items
  #Run Me: RAILS_ENV=production rake revs:fix_missing_dates state_id=1 # override the editstore state id
  # you can mix and match those parameters
  task :fix_missing_dates => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    dry_run = ENV['dry_run'] || false # if passed, no updates are sent to editstore
    collection = ENV['collection'] || '' # if passed, limits to this collection only
    state_id = ENV['state_id'] || 2 # defaults to the ready state in editstore, but can be overriden to "wait"
    date_field='pub_date_ssi'
    num_noop=0
    num_updated=0
    num_not_sent=0
    num_invalid=0
    num_errors=0

    start_time=Time.now

    q="#{date_field}:[* TO *]"
    q+=" AND collection_ssim:\"#{collection}\"" unless collection.blank?
    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>rows})

    total_docs=@all_docs['response']['docs'].size
    n=0

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}" unless collection.blank?
    puts " limited to #{limit} items" unless limit.blank?
    puts " dry run" if dry_run
    puts " found #{total_docs} items"
    puts "field checked: #{date_field}"
    puts "solr: #{Blacklight.default_index.connection.options[:url]}"
    puts "editstore enabled: #{Revs::Application.config.use_editstore}"
    puts "***********WARNING: Editstore is not enabled" unless Revs::Application.config.use_editstore
    puts ""

    @all_docs['response']['docs'].each do |doc|

      n+=1

      begin

        item=SolrDocument.new(doc)
        normalized_full_date=item.get_full_date(item.full_date)
        if normalized_full_date # we have a valid full date, compare against the MODs in PURL
          puts "#{n} of #{total_docs}: #{item.id} has a solr document date value of #{item.full_date} which is a valid full date"
          # now gets entry in mods
          response = RestClient.get("http://purl.stanford.edu/#{item.id}.mods")
          mods_xml=Nokogiri::XML(response)
          mods_date=mods_xml.css('originInfo/dateCreated')
          if mods_date.count == 1 && (item.get_full_date(mods_date.text.strip) == normalized_full_date) # dates match between MODs and Solr Document == noop
            puts "-- date matches to MODs, NOOP"
            num_noop+=1
          else
            old_date=(mods_date.count == 1 ? mods_date.text.strip : "non-existent")
            puts "-- date in MODs is #{old_date}, sending editstore update for #{date_field} to #{item.full_date}"
            if (Revs::Application.config.use_editstore && !dry_run && Editstore::Change.where(:druid=>item.id,:field=>date_field,:state_id=>state_id,:new_value=>item.full_date).count == 0) # if we are not a dry run, editstore is disabled or the update doesn't already exist, send it
              Editstore::Change.create(:new_value=>item.full_date,:old_value=>mods_date.text.strip,:operation=>:update,:state_id=>state_id,:field=>date_field,:druid=>item.id,:client_note=>'rake task to port missing full date from solr to fedora')
              num_updated+=1
            else
              num_not_sent+=1
            end
          end
        else
          num_invalid+=1
          puts "#{item.id} has a value of #{item.full_date} which is a NOT a valid full date"
        end

      rescue
        num_errors+=1
        puts "  error!"

      end

    end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} checked, #{num_errors} errors, #{num_noop} no action needed, #{num_invalid} invalid dates in solr, #{num_updated} updated in editstore, #{num_not_sent} updates not sent to edistore (existed, dry run or editstore disabled)"
    puts ""

  end

  desc "Move single valued group field to multivalued group field"
  #Run Me: RAILS_ENV=production rake revs:convert_group_to_multivalued collection="John Dugdale Collection" # limited to a collection
  #Run Me: RAILS_ENV=production rake revs:convert_group_to_multivalued limit=100 # sets a limit of number of items
  # you can mix and match those parameters
  task :convert_group_to_multivalued => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    collection = ENV['collection'] || '' # if passed, limits to this collection only
    group_field='group_ssi'
    group_field_mvf='group_ssim'
    num_updated=0
    num_errors=0

    start_time=Time.now

    q="#{group_field}:[* TO *]"
    q+=" AND collection_ssim:\"#{collection}\"" unless collection.blank?
    rows = limit.blank? ? "100000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>rows})

    total_docs=@all_docs['response']['docs'].size
    n=0

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}" unless collection.blank?
    puts " limited to #{limit} items" unless limit.blank?
    puts " found #{total_docs} items"
    puts "field checked: #{group_field}"
    puts "solr: #{Blacklight.default_index.connection.options[:url]}"
    puts ""

    @all_docs['response']['docs'].each do |doc|

      n+=1

      begin

        item=SolrDocument.new(doc)
        item.car_group=item[group_field]
        item.save
        num_updated+=1

      rescue

        num_errors+=1
        puts "  error!"

      end

    end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} checked, #{num_errors} errors, #{num_updated} updated"
    puts ""

  end

  desc "Find all objects with missing image"
  #Run Me: rake revs:missing_images["John Dugdale Collection"] to just show items
  #Run Me: rake revs:missing_images["John Dugdale Collection","delete"] to delete from solr index
  task :missing_images, [:collection_name,:delete] => :environment do |t, args|
    num_missing=0
    q="collection_ssim:\"#{args[:collection_name]}\""
    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>'100000'})
    puts "#{@all_docs['response']['numFound']} documents match search and #{@all_docs['response']['docs'].size} returned"
    @all_docs['response']['docs'].each do |doc|
      item=SolrDocument.new(doc)
      if item.is_item? && (item.images.nil? || item.images.size != 1)
        puts "#{item.id}  ---   #{item.identifier}"
        if !args[:delete].nil? && args[:delete]="delete"
          url="#{Blacklight.default_index.connection.options[:url]}/update"
          params="<delete><query>id:#{item.id}</query></delete>"
          puts "DELETING!"
          RestClient.post url, params,:content_type => :xml, :accept=>:xml
        end
        num_missing += 1
      end
    end
    puts "#{@all_docs['response']['docs'].size} scanned; #{num_missing} are missing an image"
  end

  desc "Find all objects with an image that has a space in the filename"
  #Run Me: rake revs:images_with_spaces["John Dugdale Collection"] to just show items
  task :images_with_spaces, [:collection_name,:delete] => :environment do |t, args|
    num_with_spaces=0
    q="collection_ssim:\"#{args[:collection_name]}\""
    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :rows=>'100000'})
    puts "#{@all_docs['response']['numFound']} documents match search and #{@all_docs['response']['docs'].size} returned"
    @all_docs['response']['docs'].each do |doc|
      item=SolrDocument.new(doc)
      if item.is_item? && !item.images.nil? && item.images.size != 0
        item.images.each do |image|
          if !image.match(/\s/).nil?
            puts "#{item.id}  ---   #{item.identifier}"
            num_with_spaces += 1
            next
          end
        end
      end
    end
    puts "#{@all_docs['response']['docs'].size} scanned; #{num_with_spaces} have a space in the image"
  end

  desc "Convert entrant to multivalued field"
  #Run Me: rake revs:convert_entrant
  task :convert_entrant => :environment do |t, args|
    #Have Editstore ignore updates by this rake task
    Revs::Application.config.use_editstore = false
    log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.convert_entrant#{@log_extension}")
    log.info("Starting convert_entrant")

    #Get all docs with a non-blank entrant
    total_success_count = 0
    total_error_count = 0
    results=Blacklight.default_index.connection.select(:params => {:q=>'entrant_ssi:[* TO *]',:rows=>'2000000'})

    puts "Found #{results['response']['docs'].size} documents with value in entrant_ssi field"
    results['response']['docs'].each do |result|
      doc=SolrDocument.new(result)
      druid = doc.id
      puts "Updating #{druid}"
      doc.entrant = doc['entrant_ssi']
      doc.remove_field('entrant_ssi')
      result = doc.save
      if result
        total_success_count += 1
      else
        total_error_count += 1
        log.error("Failed to save: #{druid}")
      end
    end

    if total_error_count == 0
      log.info("Run complete with #{total_success_count} converted with no errors.")
    else
      log.info("Run complete with #{total_error_count} errors and #{total_success_count} converted successfully.  #{total_error_count+total_success_count} total touches attempted on this run.")
    end

  end

  desc "Convert current_owner to text field"
  #Run Me: rake revs:convert_current_owner
  task :convert_current_owner => :environment do |t, args|
    #Have Editstore ignore updates by this rake task
    Revs::Application.config.use_editstore = false
    log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.convert_entrant#{@log_extension}")
    log.info("Starting convert_current_owner")

    #Get all docs with a non-blank current_owner
    total_success_count = 0
    total_error_count = 0
    results=Blacklight.default_index.connection.select(:params => {:q=>'current_owner_ssi:[* TO *]',:rows=>'2000000'})

    puts "Found #{results['response']['docs'].size} documents with value in current_owner_ssi field"
    results['response']['docs'].each do |result|
      doc=SolrDocument.new(result)
      druid = doc.id
      puts "Updating #{druid}"
      doc.current_owner = doc['current_owner_ssi']
      doc.remove_field('current_owner_ssi')
      result = doc.save
      if result
        total_success_count += 1
      else
        total_error_count += 1
        log.error("Failed to save: #{druid}")
      end
    end

    if total_error_count == 0
      log.info("Run complete with #{total_success_count} converted with no errors.")
    else
      log.info("Run complete with #{total_error_count} errors and #{total_success_count} converted successfully.  #{total_error_count+total_success_count} total touches attempted on this run.")
    end

  end
  desc "When passed the location of .csv file(s) and a list of headers, this will generate csv with just those fields, plus fields to find the solr document"
  #Run me: rake revs:csv_for_fields["SHEETS_LOCATION", header1|header2|etc, output_name] RAILS_ENV=production
  task :csv_for_fields, [:csv_files, :fields, :fn] => :environment do |t, args|
    always_present = [@sourceid, @filename]
    additional_headers = args[:fields].split(@seperator)
    all_fields = always_present + additional_headers
    files = load_csv_files_from_directory(args[:csv_files])
    full_output_path = "#{Rails.root}/lib/assets/#{args[:fn]}#{@csv_extension}"

    #Start Logging
    log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.csv_for_fields#{@log_extension}")
    log.level = Logger::INFO
    log.info("Starting run with the command line args of csv_fields: #{args[:csv_files]} fields: #{args[:fields]} output filename: #{args[:fn]}")

    #Setup the output csv
      CSV.open(full_output_path, "wb") do |csv|
        #Write Out The Headers
        csv << all_fields

        #Load each sheet we are taking data from
          files.each do |file|
             data = RevsUtils.read_csv_with_headers(file)
             #Make sure the always there files are present
               always_present.each do |header|
                 log.warn("File #{file} lacks required header: #{header}") if data[0].keys.include?(header) == false
               end
               data.each do |row|
                 out_array = []
                   all_fields.each do |field|
                     out_array.append(row[field])
                     log.warn("Nil value for #{field}, a required field, in #{file}") if row[field] == nil and always_present.include?(field)
                   end
                 csv << out_array
               end

          end
       end
  end

  desc "Load all changes to the metadata from CSV files located in specified folder"
  #Run me: rake revs:bulk_load["SHEETS_LOCATION"] RAILS_ENV=production column_name=marque
  # Examples:
  # rake revs:bulk_load["/users/tmp","true"] column_name=marque  # update only the marque column in local testing mode (single source ID updated only)
  # rake revs:bulk_load["/users/tmp","true"]  # update all columns in local testing mode (single source ID updated only)
  # rake revs:bulk_load["/users/tmp"] RAILS_ENV=production column_name=marque  # update only the marque column in production mode
  # rake revs:bulk_load["/users/tmp"] RAILS_ENV=production  # update all columns in production mode
  task :bulk_load, [:change_files_loc, :local_testing] => :environment do |t, args|
    column_name = ENV['column_name'] || '' # if passed, this is the only column to update
    local_testing = args[:local_testing] || false #Assume we are not testing locally unless told so
    debug_source_id = '2012-027NADI-1967-b1_1.0_0008'
    change_file_location = args[:change_files_loc]
    change_file_extension = @csv_extension_wild

    puts "Looking in #{change_file_location} for #{change_file_extension} files"
    puts "Only updating #{column_name}" unless column_name.blank?
    puts "Local testing mode with #{debug_source_id}" if local_testing
    puts "Running in #{Rails.env}"

    sourceid = @sourceid
    location = "location"
    format = "format"
    marque = "marque"
    filename = @filename
    year = "date"
    years = "years"
    full_date = "full_date"
    seperator =  @seperator
    assigner = @assigner
    multi = @mvf
    model = 'model'
    model_year = 'model_year'
    collection_name = "collection_name"
    collection_names = "collection_names"
    ignore_fields = [sourceid, location, filename, collection_name]
    location_fields = ['country', 'city', 'state']
    additional_fields = location_fields + [full_date, years]#add other arrays here if we do anymore splitting
    comma = ","
    comma_splits = [marque, model]
    file_ext = ".tif"


    #Map the csv names to the field names from
    csv_to_solr = {'label' => 'title',
                   model  => 'vehicle_model',
                   year => years,
                   format => 'formats',
                   collection_name => collection_names,
                   'inst_notes' => 'institutional_notes',
                   'prod_notes' => 'production_notes'
                  }

    solr_keys = []
    multi_values = []
    SolrDocument.field_mappings.keys.each do |key|
      solr_keys.append(key.to_s)
      multi_values.append(key.to_s) if SolrDocument.field_mappings[key][:multi_valued]
    end

   #These should be the field name from /app/models/solr_document.rb
   multi_values = ['vehicle_model', 'years', "formats", "model_year", "marque", "people", "entrant"]

   #All the CSV headers we know how to handle
   known_headers = csv_to_solr.keys + ignore_fields + solr_keys

   #Get a list of all the files we need to process and loop over them
   change_files = load_csv_files_from_directory(change_file_location)

   #Setup a master log
   master_log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.revs_bulk_load#{@log_extension}")
   sleep 1 #This way the log timestamp will be at least oen second ahead of the next log we make and the master log ends up at the top of the list

    #Process Each File
    change_files.each do |file|
      error_count = 0
      name = Pathname.new(file).basename.to_s
      name.slice! @csv_extension
      log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.#{name}#{@log_extension}")
      master_log.info("#{file} started at #{Time.now}")

      log.level = Logger::ERROR

      #Load in the CSV, with the top row being taken as the header
      changes = RevsUtils.read_csv_with_headers(file)

      #Ensure we can handle all headers we've found
      bad_header = false
      changes[0].keys.each do |header|
        if not known_headers.include?(header.strip.downcase)
          bad_header = true
          log.error("In document #{file} the #{header} is an unsupported header")
          master_log.error("#{@failure}#{file} contains unsupported header(s)")
        end
      end

      if not bad_header
        changes.each do |row|
          #Get the Solr Document and set it for updating


          #DEBUG AREA
          save_id = row[sourceid] if local_testing
          row[sourceid] = debug_source_id if local_testing

          #Attempt to get the target based on the source_id
          #target = Blacklight.default_index.connection.select(:params =>{:q=>'source_id_ssi:"'+ row['sourceid']+'"'})["response"]["docs"][0]
          target = find_doc_via_blacklight(row[@sourceid])



          #If we can't get the target based on source_id, try it with the filename
          if(target == nil and row[filename] != nil)
            alt_attempt = row[filename]
            alt_attempt.slice! file_ext
            target = find_doc_via_blacklight(alt_attempt)
            #target = Blacklight.default_index.connection.select(:params =>{:q=>'source_id_ssi:"'+ alt_attempt+'"'})["response"]["docs"][0]
          end


          #Catch sourceid with no matching druid
          if target == nil
            log.error("In document #{file} no druid found for #{row[sourceid]}")
            error_count += 1
          end

          if target != nil #Begin Altering Single Solr Document
             doc = SolrDocument.new(target)

             #If we have comma splits, replace them with the expected seperator
             comma_splits.each do |key|
               row[key] = row[key].strip.gsub(comma, seperator) if row[key] != nil
             end


             #Check to see if we have a format row and clean it up

             #Assume there is no change to the format field and we should ignore this key
             ignore_fields.insert(0, format) if not ignore_fields.include?(format)

             if row[format] != nil
               current_format = target[SolrDocument.field_mappings[:formats][:field]]
               current_format = current_format.sort if current_format != nil
               format_changes = RevsUtils.revs_check_formats(row[format].strip.downcase.split(seperator)).sort

               #We have changes
               if current_format != format_changes
                  row[format] = format_changes.join(seperator)
                  ignore_fields.delete(format) #Pull it out of the ignore fields since we need to make changes here.
                else
               end

             end

             #Check to see if we have a location and see if we need to parse it.
             row = RevsUtils.parse_location(row, location) if row[location] != nil

             #Check to see if we need need to handle marques # we will no longer auto correct marques
             # if row[marque] != nil
             #   array_marque = row[marque].split(seperator)
             #   count = 0
             #   array_marque.each do |m|
             #     result = RevsUtils.revs_lookup_marque(m)
             #     array_marque[count] = result['value'] if result
             #     count += 1
             #   end
             #   row[marque] = array_marque.join(seperator)
             #   #puts row[marque]
             #end

             #We could have a full date, a year, or a span of years, handle that.
             if row[year] != nil
               is_full_date = RevsUtils.get_full_date(row[year])

               if is_full_date
                 row[full_date] = row[year]
                 row[year] = nil if year != full_date
               else
                 row[csv_to_solr[year] || year ] = RevsUtils.parse_years(row[year]).join(seperator)
                 row[year] = nil if(csv_to_solr[year] != nil and csv_to_solr[year] != year) #Clear whatever the csv used for year/date if it is not the proper Solr key
               end
             end

             #Handle multiple model_years
             if row[model_year] != nil
               row[model_year] = RevsUtils.parse_years(row[model_year]).join(seperator)
             end

             #puts (changes[0].keys+additional_fields-ignore_fields)
             (changes[0].keys+additional_fields-ignore_fields).uniq.each do |key|
               key = key.strip.downcase
               #First make sure we have a real change
               if row[key] != nil
                 #See if the solr document calls the key something else
                   if csv_to_solr[key] != nil
                     proper_key_name = csv_to_solr[key.strip]
                   else
                     proper_key_name = key
                   end

                   #Set up multivalue and send it the value
                   update_column_name = proper_key_name.strip
                   update_column_name += multi if multi_values.include?(proper_key_name)

                   begin
                      # we need to update this field if all columns are being updated, or only a specific column is being updated, the new value of that column is NOT blank and the current value in the document IS blank
                      if column_name.blank? || ((column_name.downcase == update_column_name.downcase || column_name.downcase == proper_key_name.downcase) && doc.send(update_column_name).blank?)
                        doc.send(update_column_name+assigner, row[key].strip)
                      #  puts "Sending to #{doc.id}: #{update_column_name+assigner}'#{row[key].strip}'"
                      end
                   rescue
                       log.error("In document #{file} on row #{row[sourceid]}, failed to send the key: #{update_column_name+assigner} and value: #{row[key]}")
                   end
               end
             end

             success = doc.save

             log.error("In document #{file} save error for #{save_id} "+" #{changes[0].keys-ignore_fields+additional_fields} #{row}") if(not success and local_testing)
             log.error("In document #{file} save error for #{row[sourceid]}") if(not success and not local_testing)
             error_count  += 1 if not success

           end #End Altering Single Solr Document

        end
        master_log.info("#{@success}#{file} had no errors.") if error_count == 0
        master_log.error("#{@failure}#{file} had #{error_count} error(s).") if error_count != 0
        puts "File: #{file}" if local_testing
        puts "Errors: #{error_count}" if local_testing
      end


    end
  end

  desc "Cleanup formats in solr documents by removing extra spaces in specific format fields"
  task :cleanup_formats => :environment do
    Revs::Application.config.use_editstore = false

    formats_to_cleanup=["black-and-white film ","black-and-white negatives/color negatives "]

    formats_to_cleanup.each do |format_to_cleanup|
      results=Blacklight.default_index.connection.select(:params => {:fq=>'format_ssim:"' + format_to_cleanup + '"',:rows=>'200000'})
      puts "Found #{results['response']['docs'].size} documents with '#{format_to_cleanup}'"
      results['response']['docs'].each do |result|
        doc=SolrDocument.new(result)
        doc.update_solr('format_ssim','update',[format_to_cleanup.strip])
        puts "Updating #{doc.id}"
      end
    end

  end

  desc "Bulk hide or show images from a given spreadsheet"
  task :change_visibility, [:file, :visibility_value, :update_timestamp] => :environment do |t, args|
    # call with RAILS_ENV=production rake revs:change_visibility["/path/to/manifest.csv",1,true] to show all images not having a value in the visibility column and update the timestamp value so that docs show up in recently added
    # call with RAILS_ENV=production rake revs:change_visibility["/path/to/manifest.csv",0,false] to hide all images not having a value in the visibility column

    Revs::Application.config.use_editstore = false

    file = args[:file]
    default_visibility_value = args[:visibility_value]
    update_timestamp = args[:update_timestamp]

    raise "no spreadsheet specified or spreadsheet not found" unless File.exists?(file)
    raise "no default visibility value specified" unless default_visibility_value

    name = Pathname.new(file).basename.to_s
    name.slice! @csv_extension

    log = Logger.new("#{Rails.root}/log/change_visibility_#{Time.now.to_i}.#{name}#{@log_extension}")

    puts "Running #{file}"
    puts "Running in #{Rails.env}"
    puts "default visibility value of #{default_visibility_value}"
    puts "update timestamp is #{update_timestamp}"
    puts ""
    log.info("Running #{file}")
    log.info("Running in #{Rails.env}")
    log.info("default visibility value of #{default_visibility_value}")
    log.info("update timestamp is #{update_timestamp}")

    manifest = RevsUtils.read_csv_with_headers(file)
    error_count=0
    updated_count=0

    manifest.each do |row|

      if row[@sourceid]

        puts "...working on #{row[@sourceid]}"

        #Attempt to get the target based on the source_id
        target = find_doc_via_blacklight(row[@sourceid])

        #If we can't get the target based on source_id, try it with the filename
        if(target == nil and row[@filename] != nil)
          alt_attempt = row[@filename]
          alt_attempt.slice! file_ext
          target = find_doc_via_blacklight(alt_attempt)
        end

        #Catch sourceid with no matching druid
        if target == nil
          log.error("no druid found for #{row[@sourceid]}")
          error_count += 1
        end

        if target != nil #Begin Altering Single Solr Document
            begin
             doc = SolrDocument.new(target)
             visibility_value = ( (row[@visibility].nil? || row[@visibility].blank?) ? default_visibility_value : 0)
             puts ".....found #{doc.id}, setting visibility to #{visibility_value}"
             doc.visibility_value=visibility_value
             doc.timestamp=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ') if update_timestamp
             doc.save
             updated_count += 1
           rescue
             log.error("Could not update #{row[@sourceid]} to #{visibility_value}")
             error_count += 1
           end
        end
      end

    end
    puts "Errors: #{error_count}"
    puts "Updated: #{updated_count}"

    log.info "Errors: #{error_count}"
    log.info "Updated: #{updated_count}"

  end

  desc "Bulk hide or show images from a given collection"
  task :change_visibility_collection, [:collection_name, :visibility_value, :update_timestamp] => :environment do |t, args|
    # call with RAILS_ENV=production rake revs:change_visibility_collection["Albert R. Bochroch Photographic Archive",1,true] to show all images in the collection and update the timestamp (including the collection itself)
    # call with RAILS_ENV=production rake revs:change_visibility_collection["Albert R. Bochroch Photographic Archive",0,false] to hide all images in the collection and do not update the timestamp  (including the collection itself)

    Revs::Application.config.use_editstore = false

    collection = args[:collection_name]
    default_visibility_value = args[:visibility_value]
    update_timestamp = args[:update_timestamp]

    raise "no collection specified" unless collection
    raise "no default visibility value specified" unless default_visibility_value

    q="*:*"
    q+=" AND collection_ssim:\"#{collection}\""
    rows = "10000000"

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :fl=>'id', :rows=>rows})
    total_docs=@all_docs['response']['docs'].size

    start_time=Time.now
    n=0

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}"
    puts " default visibility value of #{default_visibility_value}"
    puts " update timestamp is #{update_timestamp}"
    puts " running in #{Rails.env}"
    puts ""

    log = Logger.new("#{Rails.root}/log/change_visibility_#{collection.gsub(' ','_')}_#{Time.now.to_i}.#{@log_extension}")

    log.info("Started at #{start_time}, #{total_docs} docs returned")
    log.info("limited to collection: #{collection}")
    log.info("running in #{Rails.env}")
    log.info("default visibility value of #{default_visibility_value}")
    log.info("update timestamp is #{update_timestamp}")
    error_count=0
    updated_count=0

    @collection_doc = Blacklight.default_index.connection.select(:params => {:q => "title_tsi:\"#{collection}\"", :fl=>'id', :rows=>50})
    @collection_doc['response']['docs'].each do |doc|
      doc = SolrDocument.find(doc['id'])
      unless doc.visibility_value.to_s == default_visibility_value.to_s  # noop if it already matches
        puts ".....setting collection #{collection} with #{doc.id} to #{default_visibility_value}"
        doc.visibility_value=default_visibility_value
        doc.timestamp=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ') if update_timestamp
        doc.save
      end
    end

    @all_docs['response']['docs'].each do |doc|

      id=doc['id']

      begin
         doc = SolrDocument.find(id)
         unless doc.visibility_value.to_s == default_visibility_value.to_s  # noop if it already matches
           puts ".....found #{doc.id}, setting visibility to #{default_visibility_value}"
           doc.visibility_value=default_visibility_value
           doc.timestamp=Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3NZ') if update_timestamp
           doc.save
           updated_count +=1
         end
       rescue
         log.error("Could not update #{id} to #{default_visibility_value}")
         error_count += 1
       end

    end
    puts ""
    puts "Errors: #{error_count}"
    puts "Updated: #{updated_count}"

    log.info "Errors: #{error_count}"
    log.info "Updated: #{updated_count}"

  end

  desc "Cleanup marques in solr documents by removing 'automobile'"
  task :cleanup_marques => :environment do
    Revs::Application.config.use_editstore = false

    results=Blacklight.default_index.connection.select(:params => {:q=>'automobiles OR automobile',:rows=>'200000'})
    puts "Found #{results['response']['docs'].size} documents with the term automobile"
    results['response']['docs'].each do |result|
      doc=SolrDocument.new(result)
      marques=doc.marque
      if marques.class == Array
        doc.update_solr('marque_ssim','update',marques.map{|marque| RevsUtils.clean_marque_name(marque)})
      end
      puts "Updating #{doc.id}"
    end

  end

  desc "Move flags to favorites for a user, run with rake revs:move_flags_to_favs['jsummer5@stanford.edu']"
  task :move_flags_to_favs, [:username] => :environment do |t, args|
      username=args[:username]  # jsummer5@stanford.edu
      user=User.where(:username=>username).limit(1).first
      if user.nil?
        puts "#{username} not found"
      else
        flags=user.flags
        if flags.size == 0
          puts "#{username} has no flags"
        else
          puts "Moving #{flags.size} flags for #{username} to favorites"
          flags.each do |flag|
            existing_fav=user.favorites.where(:druid=>flag.druid)
            if existing_fav.size == 0 # favorite doesn't exist yet, so add it
              favorite=SavedItem.save_favorite(:user_id=>user.id,:description=>flag.comment,:druid=>flag.druid)
              if favorite.id != nil
                flag.destroy
                puts "Favorite added for #{flag.druid}; flag removed"
              else
                puts "Favorite could not be added for #{flag.druid}; flag NOT removed"
              end
            else
              puts "favorite already exists for #{flag.druid}; flag NOT removed"
            end
        end
      end
    end
  end

  desc "Move open flag comments to item descriptions for a user, run with rake revs:move_flags_to_desc['Doug Nye']"
  task :move_flags_to_desc, [:username] => :environment do |t, args|
      username=args[:username]
      user=User.where(:username=>username).limit(1).first
      if user.nil?
        puts "#{username} not found"
      else
        puts "Started at #{Time.now}"
        flags=user.flags.where(:state=>Flag.open)
        if flags.size == 0
          puts "#{username} has no flags"
        else
          puts "Moving #{flags.size} flag comments for #{username} to item descriptions and setting flags to in review"
          flags.each do |flag|
            puts "...working on #{flag.druid}"
            STDOUT.flush
            flag.move_to_description
            flag.save
          end # end loop over open flags
        end # end check for any flags
        puts "Finished at #{Time.now}"
      end # end check for existing user
  end # end rake task

  desc "Reset sort order for galleries"
  task :reset_gallery_order => :environment do |t,args|
    n=0
    Gallery.public_galleries.order('created_at').each do |gallery|
       gallery.update_column(:row_order_position,n)
      n+=1
    end
  end

  desc "Reset sort order for all saved items"
  task :reset_saved_item_order => :environment do |t,args|
    n=0
    SavedItem.order('created_at').each do |item|
      item.update_column(:row_order_position,n)
      n+=1
    end
  end

  desc "Export flags to CSV file, run with rake revs:export_flags['open']"
  task :export_flags, [:state] => :environment do |t, args|
    state = args[:state]
    full_output_path = File.join(Rails.root,"tmp","flags_#{state}.csv")
    flag_counts = Flag.where(:state=>state).count

    puts "Exporting #{flag_counts} flags with state #{state} to #{full_output_path}"

    CSV.open(full_output_path, "wb") do |csv|
      csv << ["id","druid","sourceid","item title","comment","username","user_role","date_created","state"]
      Flag.where(:state=>state).find_each do |flag|
        username = flag.user.blank? ? "anonymous" : flag.user.username
        user_role = flag.user.blank? ? "n/a" : flag.user.role
        csv << [flag.id,flag.druid,flag.source_id,flag.item.title,flag.comment,username,user_role,flag.created_at,flag.state]
      end
    end
  end

  desc "Move annotations to flags for a user, run with rake revs:move_annotations_to_flags['Doug Nye']"
  task :move_annotations_to_flags, [:username] => :environment do |t, args|
      username=args[:username]
      user=User.where(:username=>username).limit(1).first
      if user.nil?
        puts "#{username} not found"
      else
        annotations=user.annotations
        if annotations.size == 0
          puts "#{username} has no annotations"
        else
          puts "Moving #{annotations.size} annotations for #{username} to flags"
          annotations.each do |annotation|
            flag=Flag.create_new({:flag_type=>:error,:comment=>annotation.text,:druid=>annotation.druid},user)
            if flag.id != nil
              flag.created_at=annotation.created_at # have the date match the annotation date
              flag.save
              annotation.destroy
              puts "Flag added for #{annotation.druid}; annotation removed"
            else
              puts "Flag could not be added for #{annotation.druid}; annotation NOT removed"
            end
          end
        end
      end
    end

  class RevsUtils
    extend Revs::Utils
    include Revs::Utils
  end

  def load_csv_files_from_directory(file_location)
    return Dir.glob(File.join(file_location, @csv_extension_wild))
  end

  def find_doc_via_blacklight(source)
     return Blacklight.default_index.connection.select(:params =>{:q=>'source_id_ssi:"'+ source+'"'})["response"]["docs"][0]
  end

  #Note, this function doesn't save the document, I just return a content string!
  def join_content(doc, field, content)
    current_content = doc[SolrDocument.field_mappings[field][:field]]
    return content if current_content == nil
    current_content = current_content.join(@seperator) if SolrDocument.field_mappings[field][:multi_valued]
    current_content = current_content + content
    return current_content
  end

  def get_args_for_send(field)
    args = @assigner
    args = @mvf + args if SolrDocument.field_mappings[field][:multi_valued]
    return args
  end


  #Note you will need to refetch the document to see the changes after calling this function
  def update_multi_fields(doc, changes)
    #Fields is expected to be in the form of [[field, content, append]]
    #Ex: [[:title, "My New Title"],[:people, "Person I Forgot To List", true]]
    changes.each do |change|
      content = change[1]
      content = join_content(doc, change[0], change[1]) if change[2]
      doc.send(change[0].to_s+get_args_for_send(change[0]),content)
    end
    return doc.save #Returns true if this all worked
  end

end
