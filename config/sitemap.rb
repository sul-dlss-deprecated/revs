# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://revslib.stanford.edu"

SitemapGenerator::Sitemap.create do

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  @max_expected_collection_size = 2147483647 # big honkin' number

  # add some static pages
  add all_collections_path, :changefreq => 'weekly'
  add galleries_path, :changefreq => 'daily'
  add about_project_path, :changefreq => 'monthly'
  add contact_us_path, :changefreq => 'monthly'
  add tutorials_path, :changefreq => 'monthly'

  collections=SolrDocument.all_collections

  puts "Found #{collections.size} total collections"
  total_images=0

  # iterate over all collections and all add all items
  collections.each do |collection|

      add collection_path(collection.id), :lastmod => collection['timestamp'] # add the collection object

      result=Blacklight.solr.select(:params => {:q=>'is_member_of_ssim:"' + collection.id + '"',:rows=>@max_expected_collection_size}) # get all members of the collection
      puts ".working on collection #{collection.id}: #{collection.title} with #{result['response']['numFound']} total images"
      total_images+= result['response']['numFound']

      result['response']['docs'].each do |doc|
        add item_path(doc['id']), :lastmod => doc['timestamp']
      end

  end

  puts ""
  puts "Found #{total_images} total images in #{collections.size} collections"

end
