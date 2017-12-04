# before doing stuff with fixtures, be sure we are not running in production or pointing to a actual real solr server
def allowed_solr?
  !Rails.env.production? && !Rails.env.staging?
end

require 'solr_wrapper/rake_task' if allowed_solr?
require 'rest_client'

desc "Start a development server"
task :server do
  Rails.env='development'
  ENV['RAILS_ENV']='development'
  SolrWrapper.wrap do |solr|
    solr.with_collection do
      Rake::Task["revs:refresh_fixtures"].invoke
      system('bundle exec rails server')
    end
  end
end

desc "Run continuous integration suite"
task :ci do
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Rake::Task["revs:config"].invoke
  SolrWrapper.wrap do |solr|
    solr.with_collection do
      Rake::Task["local_ci"].invoke
    end
  end
end

desc "Assuming jetty is already running - then migrate, reload all fixtures and run rspec"
task :local_ci do
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Rake::Task["db:migrate"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["db:fixtures:load"].invoke
  Rake::Task["db:seed"].invoke
  Rake::Task["revs:refresh_fixtures"].invoke
  Rake::Task["revs:update_item_title"].invoke
  Rake::Task["rspec"].invoke
end

namespace :revs do

  desc "Check development options"
  task :dev_options_set => :environment do
    if Revs::Application.config.simulate_sunet_user || !Revs::Application.config.use_editstore
      puts '**************************************************************'
      puts '****** WARNING: SOME DEVELOPMENT ONLY OPTIONS ARE SET ********'
      puts '**************************************************************'
    end
  end

  desc "Copy configuration files"
  task :config do
    config_files = %w{database.yml blacklight.yml secrets.yml}
    config_files.each {|config_file| cp("#{Rails.root}/config/#{config_file}.example", "#{Rails.root}/config/#{config_file}") unless File.exists?("#{Rails.root}/config/#{config_file}.yml")}
  end

  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    if allowed_solr?
      Rake::Task["revs:delete_records_in_solr"].invoke
      Rake::Task["revs:index_fixtures"].invoke
    else
      puts "Refusing to refresh fixtures.  You know, for safety.  Check your solr config."
    end
  end

  desc "Index all fixtures into solr"
  task :index_fixtures do
    if allowed_solr?
      add_docs = []
      Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
        add_docs << File.read(file)
      end
      puts "Adding #{add_docs.count} documents to #{Blacklight.default_index.connection.options[:url]}"
      RestClient.post "#{Blacklight.default_index.connection.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
    else
      puts "Refusing to index fixtures.  You know, for safety.  Check your solr config."
    end
  end

  desc "Clean up saved items - remove any saved items which reference items/solr documents that do not exist"
  task :cleanup_saved_items => :environment do |t, args|
    SavedItem.all.each { |saved_item| saved_item.destroy if saved_item.solr_document.nil? }
  end

  desc "Delete all records in solr"
  task :delete_records_in_solr do
    if allowed_solr?
      puts "Deleting all solr documents from #{Blacklight.default_index.connection.options[:url]}"
      RestClient.post "#{Blacklight.default_index.connection.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Refusing to delete fixtures.  You know, for safety.  Check your solr config."
    end
  end
end
