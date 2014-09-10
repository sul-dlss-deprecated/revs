source 'https://rubygems.org'
source 'http://sul-gems.stanford.edu'

ruby "1.9.3"

gem 'bundler', '>= 1.2.0'

gem 'sitemap_generator'

gem 'editstore', '>= 1.1.5'
gem 'revs-utils', '>= 1.0.8'

gem 'rails', '~> 3.2.19'

# user authentication and roles
gem 'devise', '~> 2.2.5'
gem 'omniauth'
gem 'cancan'

gem 'ranked-model'

gem 'friendly_id', '~> 4.0.10'

# image (user avatar) uploading
gem 'carrierwave'
gem "mini_magick"

gem 'whenever', :require => false

gem 'addressable'

# paging
gem 'kaminari'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

#gem "blacklight", :git => 'https://github.com/projectblacklight/blacklight.git'
gem 'blacklight', ">= 5.3.0"
gem "blacklight_range_limit", ">=5.0.2"
gem 'blacklight-marc'
gem 'druid-tools', '>= 0.2.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'rspec-rails'
  gem 'capybara', '~> 1.0'
end

group :development do
	gem 'better_errors'
	gem 'binding_of_caller'
	gem 'meta_request'
	gem 'launchy'
  gem 'thin'
  gem 'quiet_assets'
end

group :development, :staging, :test do
  gem 'jettywrapper'
  gem 'sqlite3'
  #gem 'rspec-core', "2.99"
end

group :staging, :production do
  gem 'mysql2'
end

# gems necessary for capistrano deployment
group :development,:deployment do
  gem 'capistrano', '~>2'
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
  gem 'lyberteam-devel', '>=1.0.0'
  gem 'lyberteam-gems-devel', '>=1.0.0'
	gem 'lyberteam-capistrano-devel', '>= 1.1.0'
  gem 'net-ssh-krb'
end
gem 'gssapi', :git => 'https://github.com/cbeer/gssapi.git'

gem 'jquery-rails'
gem 'rest-client'

gem 'json', '~> 1.8'

gem "bootstrap-sass"
gem "font-awesome-rails"

gem 'squash_ruby', :require => 'squash/ruby'
gem 'squash_rails', :require => 'squash/rails'

#Bulk Metadata Loading Gems
gem 'countries'
