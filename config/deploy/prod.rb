set :bundle_without, %w{deployment test development staging}.join(' ')
set :rails_env, "production"
set :deploy_host, "revs-prod"
server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

after  "deploy:finishing", "jetty:remove"
