require 'io/console'

namespace :revs do
  desc "Export all users of this role to a CSV file"
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_users role="curator"
  task :export_users => :environment do |t, args|
    role = ENV['role'] || 'curator' # limit to this role, curator by default
    full_output_path = File.join(Rails.root,"tmp","users_#{role}.csv")
    active_users=User.where(:role=>role,:active=>true)
    puts "Exporting #{active_users.count} active users of role #{role} to #{full_output_path}"
    CSV.open(full_output_path, "wb") do |csv|
      csv << ["full_name","username","email","registered","last_sign_in","total_logins"]
      active_users.each do |user|
        csv << [user.full_name,user.username,user.email,user.created_at,user.last_sign_in_at,user.login_count]
      end
    end
  end


  desc "Destroy any non-SUNET users older than 1 month who have never logged in or confirmed their accounts"
  task :purge_unconfirmed_users => :environment do |t,args|
    unconfirmed_users=User.where(:confirmed_at=>nil,:last_sign_in_at=>nil,:sunet=>'').where("updated_at < ?",4.weeks.ago)
    puts "Destroying #{unconfirmed_users.size} unconfirmed users"
    unconfirmed_users.each do |user|
      puts "...destroying '#{user.username}'"
      user.destroy
    end
  end

  desc "Destroy any non-SUNET users older than the given timeframe who are inactive and who have not logged in (i.e. required manual activation but did not receive it)"
  task :purge_inactive_users, [:timeframe] => :environment do |t,args|
    timeframe = args[:timeframe] || 2.weeks.ago # users older than this timeframe will be removed (default to 2 weeks)
    User.purge_inactive(timeframe)
  end

  desc "Destroy users with confirmation"
  task :cleanup_users => :environment do |t,args|
    $stdout.sync = true
    deleted = 0
    users = User.where('sunet = ""').order('created_at asc')
    total = users.count
    puts
    puts "#{total} total users.  Press y to delete"
    users.each do |user|
        print "#{user.created_at}\t#{user.username}\t#{user.email}\t#{user.url}\t#{user.bio}\t#{user.saved_items.count} saved items\t#{user.login_count} logins: "
        input = STDIN.getch
        puts input
        if input.chomp == 'y'
          deleted += 1
          user.destroy
          puts "***DELETED"
        end
    end
    puts
    puts "#{total} total users; #{deleted} were deleted."
  end

  desc "Notify administrator of new registrants"
  task :notify_new_registrations => :environment do |t,args|
    num_unconfirmed_users=User.where(:active=>false,:sunet=>'',:login_count=>0).where('updated_at < ?',Date.tomorrow).size
    if num_unconfirmed_users > 0
      RevsMailer.new_users_notification(:num_users=>num_unconfirmed_users).deliver
      puts "Found #{num_unconfirmed_users} users."
    end
  end

  desc "Inactivate the provided users and destroy any of their contributions, e.g. galleries, annotations, flags (useful for spam users)"
  #Run Me: RAILS_ENV=production bundle exec rake revs:inactivate_users users="user1,some_spammy_guy,another_bad_dude"
  task :inactivate_users => :environment do |t,args|
    users = ENV['users']
    raise '*** no users supplied, pass in a users="username1,username2" parameter' if users.blank?
    usernames=users.split(',')
    puts "Inactivating #{usernames.size} users"
    usernames.each do |username|
      user = User.find_by_username(username.strip)
      if user
        puts "...inactivating '#{username}'"
        user.ban
      else
        puts "*** '#{username}' not found"
      end
    end
  end

end
