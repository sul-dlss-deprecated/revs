set :output, "/home/lyberadmin/revs-lib/current/log/revs_cron.log"

if ['production','staging'].include? @environment
  every 5.days do
    rake "blacklight:delete_old_searches[5]"
  end
end

# Learn more: http://github.com/javan/whenever