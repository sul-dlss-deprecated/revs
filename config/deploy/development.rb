set :rails_env, "development"
set :deployment_host, "revs-dev.stanford.edu"
set :bundle_without, [:deployment]

role :web, deployment_host, :primary => true
role :app, deployment_host
role :db,  deployment_host, :primary => true


namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end

after "deploy:finalize_update", "db:symlink_sqlite"
after "deploy:finalize_update", "jetty:remove"
after "deploy:finalize_update", "fixtures:refresh"
after "deploy:create_symlink", "db:loadseeds"
