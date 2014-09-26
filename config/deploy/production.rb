server "revs-prod.stanford.edu", user: 'lyberadmin', roles: %w{web db app}
Capistrano::OneTimeKey.generate_one_time_key!
set :bundle_without, [:deployment,:development,:test,:staging]
set :rails_env, "production"

after "deploy:finalize_update", "jetty:remove"