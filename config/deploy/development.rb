server "revs-dev.stanford.edu", user: 'lyberadmin', roles: %w{web db app}
#Capistrano::OneTimeKey.generate_one_time_key!
set :bundle_without, [:deployment]
set :rails_env, "development"

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
