Rails.configuration.middleware.use(IsItWorking::Handler) do |h|

  h.check :version do |status|
    status.ok(IO.read(Rails.root.join('VERSION')).strip)
  end

  h.check :revision do |status|
    status.ok(IO.read(Rails.root.join('REVISION')).strip)
  end

  # Check the ActiveRecord database connection without spawning a new thread
  h.check :active_record, :async => false

  # Check the home page
  h.check :url, :get => "https://automobility.stanford.edu"

  # Check the about page
  h.check :url, :get => "https://automobility.stanford.edu/about"

  # check an item detail page
  h.check :url, :get => "https://automobility.stanford.edu/item/tp537fn9045"

  h.check :search_result do |status|
    url="https://automobility.stanford.edu/?q=buick"
    response = RestClient.get(url)
    fail 'has a bad response' unless response.code == 200
    if response.body.include?("<strong>1</strong> - <strong>10</strong> of") # could be any number of large results
      status.ok('has results')
    else
      fail 'is missing results'
    end
  end

  h.check :collections_page do |status|
    url="https://automobility.stanford.edu/collection"
    response = RestClient.get(url)
    fail 'has a bad response' unless response.code == 200
    if response.body.include?("Road & Track magazine records") # the road & track archive
      status.ok('has results')
    else
      fail 'is missing results'
    end
  end

end
