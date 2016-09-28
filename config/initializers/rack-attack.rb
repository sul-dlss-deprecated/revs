BANNED_IPS=["107.6.154.","216.218.147.199","178.27.30.234","141.8.143.146"] # array of banned ips... to block subnets, only include the first part
# (e.g. "10.11." or "10.11.1." or "10.11.1.123") blocks in increasing specificity

class Rack::Attack

  ### Configure Cache ###

    # If you don't want to use Rails.cache (Rack::Attack's default), then
    # configure it here.
    #
    # Note: The store is only used for throttling (not blacklisting and
    # whitelisting). It must implement .increment and .write like
    # ActiveSupport::Cache::Store

    # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    ### Throttle Spammy Clients ###

    # If any single client IP is making tons of requests, then they're
    # probably malicious or a poorly-configured scraper. Either way, they
    # don't deserve to hog all of the app server's CPU. Cut them off!
    #
    # Note: If you're serving assets through rack, those requests may be
    # counted by rack-attack and this throttle may be activated too
    # quickly. If so, enable the condition to exclude them from tracking.

    # Throttle all requests by IP (60rpm)
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
    throttle('req/ip', :limit => 300, :period => 5.minutes) do |req|
      req.ip # unless req.path.starts_with?('/assets')
    end

    ### Prevent Brute-Force Login Attacks ###

    # The most common brute-force login attack is a brute-force password
    # attack where an attacker simply tries a large number of emails and
    # passwords to see if any credentials match.
    #
    # Another common method of attack is to use a swarm of computers with
    # different IPs to try brute-forcing a password for a specific account.

    # Throttle POST requests to /users/sign_in by IP address
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
    throttle('users/sign_in/ip', :limit => 5, :period => 20.seconds) do |req|
      if req.path == '/users/sign_in' && req.post?
        req.ip
      end
    end

    # Throttle POST requests to /login by email param
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{req.email}"
    #
    # Note: This creates a problem where a malicious user could intentionally
    # throttle logins for another user and force their login requests to be
    # denied, but that's not very common and shouldn't happen to you. (Knock
    # on wood!)
    throttle("users/password", :limit => 5, :period => 20.seconds) do |req|
      if req.path == '/users/password' && req.post?
        # return the email if present, nil otherwise
        req.params['email'].presence
      end
    end
end

Rack::Attack.whitelist('allow from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip
end

Rack::Attack.blacklist('block banned IPs') do |req|
  # Requests are blocked if the return value is truthy
  !(req.ip =~ Regexp.union(BANNED_IPS)).nil?
end

# Block requests containing '/etc/password' in the params.
# After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
Rack::Attack.blacklist('fail2ban pentesters') do |req|
  # `filter` returns truthy value if request fails, or if it's from a previously banned IP
  # so the request is blocked
  Rack::Attack::Fail2Ban.filter(req.ip, :maxretry => 3, :findtime => 10.minutes, :bantime => 5.minutes) do
    # The count for the IP is incremented if the return value is truthy.
    CGI.unescape(req.query_string) =~ %r{/etc/passwd}
  end
end
