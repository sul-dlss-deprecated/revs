set :rails_env, "staging"
set :deployment_host, "revs-stage.stanford.edu"
set :bundle_without, [:deployment, :development, :test]

DEFAULT_TAG='master'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

#before "deploy", "jetty:stop"
after "deploy:finalize_update", "db:symlink_sqlite"
#after "deploy:finalize_update", "jetty:symlink"
#after "jetty:symlink", "jetty:start"
