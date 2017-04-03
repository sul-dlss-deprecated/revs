set :bundle_without, %w{deployment test development}.join(' ')
set :rails_env, "staging"
set :deploy_host, "revs-stage"
server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

after  "deploy:finishing", "jetty:remove"
