require 'jettywrapper'
require 'rest_client'

desc "Run continuous integration suite"
task :ci do
  unless Rails.env.test?  
    system("rake ci RAILS_ENV=test")
  else
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task["revs:refresh_fixtures"].invoke
      Rake::Task["rspec"].invoke
    end
  end
end

desc "Stop dev jetty, run `rake ci`, start dev jetty."
task :local_ci do  
  system("rake jetty:stop")
  system("rake db:migrate RAILS_ENV=test")  
  system("rake jetty:start RAILS_ENV=test")
  system("rake revs:refresh_fixtures RAILS_ENV=test")
  system("bundle exec rspec")
  system("rake jetty:stop RAILS_ENV=test")  
  system("rake jetty:start")
end


namespace :revs do
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    Rake::Task["revs:delete_records_in_solr"].invoke
    Rake::Task["revs:index_fixtures"].invoke
  end
  
  desc "Index all fixutres into solr"
  task :index_fixtures do
    add_docs = []
    Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
      add_docs << File.read(file)
    end
    puts "Adding #{add_docs.count} documents to #{Blacklight.solr.options[:url]}"
    RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
  end
  
  desc "Delete all records in solr"
  task :delete_records_in_solr do
   unless Rails.env.production?
      puts "Deleting all solr documents from #{Blacklight.solr.options[:url]}"
      RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Did not delete since we're running under the #{Rails.env} environment and not under test. You know, for safety."
    end
  end
end