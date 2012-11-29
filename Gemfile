source 'https://rubygems.org'

gem 'bundler', '>= 1.2.0'

ruby "1.9.3"

gem 'rails', '3.2.9'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "blacklight", :git => 'https://github.com/projectblacklight/blacklight.git'

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
  gem 'capybara'
end

group :development, :staging, :test do
  gem 'jettywrapper'
  gem 'rest-client'
  gem 'sqlite3'
end

gem 'jquery-rails'

gem "bootstrap-sass"

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'