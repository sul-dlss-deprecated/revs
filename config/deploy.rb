# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, "revs-lib"
set :repo_url, "https://github.com/sul-dlss/revs"
set :user, ask("User", 'enter in the app username')

set :home_directory, "/home/#{fetch(:user)}"
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

set :stages, %W(staging development production)

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/solr.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/uploads}

last_tag = `git describe --abbrev=0 --tags`.strip
default_tag='master'
set :tag, ask("Tag to deploy (make sure to push the tag first): [default: #{default_tag}, last tag: #{last_tag}] ", default_tag)

set :branch, fetch(:tag)

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
  end
  after :publishing, :restart

end

before 'deploy:compile_assets', 'squash:write_revision'
before "deploy:finishing", "deploy:dev_options_set"
after  "deploy:finishing", "deploy:symlink_editstore"
