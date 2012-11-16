set :rails_env, "staging"
set :deployment_host, "revs-stage.stanford.edu"
set :bundle_without, [:deployment, :development]

DEFAULT_TAG='master'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true