set :rails_env, "development"
set :deployment_host, "revs-dev.stanford.edu"
set :bundle_without, [:deployment]

DEFAULT_TAG='master'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true


namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end


before "deploy", "jetty:stop"
after "deploy:update_code", "db:symlink_sqlite"
after "deploy:update_code", "jetty:symlink"
after "deploy", "jetty:start"
#after "deploy", "db:loadfixtures"  # no need to load fixtures of index because we share jetty between deploys
#after "jetty:start", "jetty:ingest_fixtures"