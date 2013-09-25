source 'https://rubygems.org'
source 'http://sul-gems.stanford.edu'

gem 'bundler', '>= 1.2.0'

gem 'editstore', '>= 0.1.5'

ruby "1.9.3"

gem 'rails', '>= 3.2.11'

gem 'google-analytics-rails'

# user authentication and roles
gem 'devise', '~> 2.2.5'
gem 'omniauth'
gem 'cancan'

# image (user avatar) uploading
gem 'carrierwave'
gem "mini_magick"

# paging
gem 'kaminari'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "blacklight", :git => 'https://github.com/projectblacklight/blacklight.git'
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
end

group :development, :staging, :test do
  gem 'jettywrapper'
  gem 'sqlite3'
end

group :staging, :production do
  gem 'mysql', "2.8.1"
end

gem 'jquery-rails'
gem 'rest-client'

gem 'json', '~> 1.7.7'

gem "bootstrap-sass"
gem "font-awesome-rails"
