namespace :revs do
  desc "Show all users of this role on the screen for easy saving to CSV file"
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_users role="curator"
  task :export_users => :environment do |t, args|
    role = ENV['role'] || 'curator' # limit to this role, curator by default
    active_users=User.where(:role=>role,:active=>true)
    puts "full_name,username,email,registered,last_sign_in,total_logins"
    active_users.each {|user| puts "#{user.full_name},#{user.username},#{user.email},#{user.created_at},#{user.last_sign_in_at},#{user.login_count}"}
  end
end
