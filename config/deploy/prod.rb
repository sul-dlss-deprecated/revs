set :bundle_without, %w{deployment test development staging}.join(' ')
set :rails_env, "production"
server 'revs-prod.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

after  "deploy:finishing", "jetty:remove"
