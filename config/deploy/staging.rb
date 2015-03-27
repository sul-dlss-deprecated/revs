set :bundle_without, %w{deployment test development}.join(' ')
set :rails_env, "staging"

Capistrano::OneTimeKey.generate_one_time_key!

after  "deploy:finishing", "jetty:remove"