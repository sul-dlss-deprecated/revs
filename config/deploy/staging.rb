set :rails_env, "staging"
set :deployment_host, "revs-stage.stanford.edu"
set :bundle_without, [:deployment, :development, :test]

DEFAULT_TAG='master'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

before "deploy", "jetty:stop"
before "deploy:migrate", "db:symlink_sqlite"
after "deploy", "jetty:start"
after "deploy", "db:loadfixtures"
after "jetty:start", "revs:index_fixtures"
