server "revs-stage.stanford.edu", user: 'lyberadmin', roles: %w{web db app}
#Capistrano::OneTimeKey.generate_one_time_key!
set :bundle_without, [:deployment,:development,:test]
set :rails_env, "staging"

after "deploy:finalize_update", "jetty:remove"