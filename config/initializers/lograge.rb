Revs::Application.configure do
  config.lograge.enabled = true

  # add time to lograge
  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params].reject do |k|
      ['controller', 'action'].include? k
    end
    {:params=>params}
  end
end