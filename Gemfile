source 'https://rubygems.org'

ruby "2.2.2"

gem 'bundler', '>= 1.2.0'

# add these gems to help with the transition:
# gem 'rails-observers'
# gem 'actionpack-page_caching'
# gem 'actionpack-action_caching'

gem 'sitemap_generator'

gem 'editstore', '>= 2.0.2'
gem 'revs-utils', '>= 2.0.10'

gem 'rails', '>= 4'
gem 'responders', '~> 2.0'

# user authentication and roles
gem 'devise'
gem 'omniauth'
gem 'cancan'

gem 'ranked-model'

gem 'friendly_id', '>= 5.0.0'

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
gem 'sass-rails', '~> 5.0.0.beta1'
gem 'coffee-rails', '~> 4.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', :platforms => :ruby

gem 'uglifier', '>= 1.0.3'

group :test do
  gem 'rspec-rails'
  gem 'capybara'
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
end

group :staging, :production do
  gem 'mysql2'
end

# gems necessary for capistrano deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel', '~>3'
  gem 'capistrano-rvm'
end

gem 'jquery-rails'
gem 'rest-client', '~>1.7'

gem 'json', '~> 1.8'

gem "bootstrap-sass"
gem "font-awesome-rails"
gem 'autoprefixer-rails', '~> 5.1.11'

gem 'squash_ruby', :require => 'squash/ruby'
gem 'squash_rails', :require => 'squash/rails'

#Bulk Metadata Loading Gems
gem 'countries'
