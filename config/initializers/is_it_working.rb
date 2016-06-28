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
  h.check :url, :get => "https://revslib.stanford.edu"

  # Check the about page
  h.check :url, :get => "https://revslib.stanford.edu/about"

  # check an item detail page
  h.check :url, :get => "https://revslib.stanford.edu/item/yk807wq6530"

  h.check :search_result do |status|
    url="https://revslib.stanford.edu/?q=chevrolet"
    response = RestClient.get(url)
    fail 'has a bad response' unless response.code == 200
    if response.body.include?("<strong>1</strong> - <strong>10</strong> of ") # could be any number of large results
      status.ok('has results')
    else
      status.ok('is missing results')
    end
  end

  h.check :collections_page do |status|
    url="https://revslib.stanford.edu/collection"
    response = RestClient.get(url)
    fail 'has a bad response' unless response.code == 200
    if response.body.include?("<strong>1</strong> - <strong>12</strong> of ") # could be any number greater than 12
      status.ok('has results')
    else
      status.ok('is missing results')
    end
  end

end
