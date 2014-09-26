# config valid only for Capistrano 3.1
lock '3.2.1'

require 'squash/rails/capistrano3'
require 'whenever/capistrano'

set :application, "revs-lib"
set :repo_url, "https://github.com/sul-dlss/revs"
set :deploy_to, "/home/lyberadmin/revs-lib"

set :stages, %W(staging development production)

set :deploy_via, :remote_cache
set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { stage }

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/solr.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/uploads}

set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false

set :branch do
  last_tag = `git describe --abbrev=0 --tags`.strip
  default_tag = 'master'
  
  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [default: #{default_tag}, last tag: #{last_tag}] "
  tag = default_tag if tag.empty?
  tag
end

namespace :jetty do
  task :start do 
    run "cd #{deploy_to}/current && rake jetty:start RAILS_ENV=#{rails_env}"
  end
  task :stop do
    run "if [ -d #{deploy_to}/current ]; then cd #{deploy_to}/current && rake jetty:stop RAILS_ENV=#{rails_env}; fi"
  end
  task :remove do
    run "rm -fr #{release_path}/jetty"
  end  
  task :symlink do
    run "rm -fr #{release_path}/jetty"
    run "ln -s #{shared_path}/jetty #{release_path}/jetty"
  end
end

namespace :fixtures do
  task :ingest do
    run "cd #{deploy_to}/current && rake revs:index_fixtures RAILS_ENV=#{rails_env}"
  end
  task :refresh do
    run "cd #{deploy_to}/current && rake revs:refresh_fixtures RAILS_ENV=#{rails_env}"
  end
end

namespace :db do
  task :migrate do
    run "cd #{deploy_to}/current && rake db:migrate RAILS_ENV=#{rails_env}"
  end
  task :loadfixtures do
    run "cd #{deploy_to}/current && rake db:fixtures:load RAILS_ENV=#{rails_env}"
  end
  task :loadseeds do
    run "cd #{deploy_to}/current && rake db:seed RAILS_ENV=#{rails_env}"
  end  
  task :symlink_sqlite do
    run "ln -s #{shared_path}/#{rails_env}.sqlite3 #{release_path}/db/#{rails_env}.sqlite3"
  end  
end

namespace :deploy do
  task :symlink_editstore do
    run "ln -s /home/lyberadmin/editstore-updater/current/public #{release_path}/public/editstore"
  end  
  task :dev_options_set do
    run "cd #{deploy_to}/current && rake revs:dev_options_set RAILS_ENV=#{rails_env}"
  end
  task :start do ; end
  task :stop do ; end
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  after :publishing, :restart

end

before 'deploy:compile_assets', 'squash:write_revision'
after "deploy:update", "deploy:dev_options_set"
after "deploy:finalize_update", "deploy:symlink_editstore"
