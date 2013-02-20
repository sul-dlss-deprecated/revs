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
after "deploy:finalize_update", "db:symlink_sqlite"
after "deploy:finalize_update", "jetty:symlink"
after "jetty:symlink", "jetty:start"
after "jetty:start", "jetty:refresh_fixtures"
after "deploy:create_symlink", "db:loadseeds"
