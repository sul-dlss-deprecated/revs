set :deploy_host, ask("Server", 'enter in the server you are deploying to. do not include .stanford.edu')
server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

set :bundle_without, %w{deployment test}.join(' ')
set :rails_env, "development"

Capistrano::OneTimeKey.generate_one_time_key!

namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end

before  "deploy:updated", "db:symlink_sqlite"
after  "deploy:finishing", "jetty:remove"
after  "deploy:finished", "fixtures:refresh"
after  "deploy:finished", "db:loadseeds"
