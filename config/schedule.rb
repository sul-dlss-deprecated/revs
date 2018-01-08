set :output, "/home/lyberadmin/revs-lib/current/log/revs_cron.log"

if ['production','staging'].include? @environment

  every 5.days, :at => '12:00 am' do
    rake "blacklight:delete_old_searches[5]"
  end

  every 1.days, :at => '1:00 am' do
    rake "revs:notify_new_registrations"
  end

  every 1.days, :at => '2:00 am' do
    rake "revs:purge_unconfirmed_users"
  end

  every 1.days, :at => '3:00 am' do
    rake "revs:purge_inactive_users"
  end


end

if ['production'].include? @environment

  every 1.week, :at => '2:00 am' do
    rake "-s sitemap:refresh"
  end

end
