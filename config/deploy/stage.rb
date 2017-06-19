set :bundle_without, %w{deployment test development}.join(' ')
set :rails_env, "staging"
server "revs-stage.stanford.edu", user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

after  "deploy:finishing", "jetty:remove"
