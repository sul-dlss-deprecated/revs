namespace :revs do
  desc "Show all users of this role on the screen for easy saving to CSV file"
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_users role="curator"
  task :export_users => :environment do |t, args|
    role = ENV['role'] || 'curator' # limit to this role, curator by default
    active_users=User.where(:role=>role,:active=>true)
    puts "full_name,username,email,registered,last_sign_in,total_logins"
    active_users.each {|user| puts "#{user.full_name},#{user.username},#{user.email},#{user.created_at},#{user.last_sign_in_at},#{user.login_count}"}
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
end
