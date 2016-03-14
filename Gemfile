source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.13'

gem 'rails', '3.2.18'

gem 'devise'
gem 'foreman'
gem 'uuidtools'
gem 'activeuuid'
gem "bcrypt-ruby", "~> 3.0"
gem "ec2-snapshot"

gem 'nokogiri', '1.6.1'

# For Cloudinary migration
gem 'jdbc-sqlite3'
gem 'activerecord-jdbcsqlite3-adapter'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'


# gem 'activerecord-jdbcpostgresql-adapter'#,  '1.2.9'
gem 'activerecord-jdbcpostgresql-adapter', '1.3.1'
#github: 'jruby/activerecord-jdbc-adapter', branch: 'master'

# gem 'postgres_ext'
gem 'jdbc-postgres'
gem 'activerecord-postgres-hstore'
gem 'validation'
gem 'jrjackson'

gem 'cloudinary'

# gem 'orientdb', github: 'aemadrid/orientdb-jruby'
gem 'oriented', github: 'ruprict/oriented', branch: 'master'
gem 'orientdb', github: 'KYCK/orientdb-jruby', branch: '1.7.10'
gem 'hooks'

gem 'newrelic_rpm'
gem 'remote_syslog_logger'

gem 'counter_culture'

# Intercept emails if ENV['EMAIL_RECIPIENTS'] is set
gem 'recipient_interceptor'

gem "torquebox-server", '~>3.1.1'
gem "torquebox",'~>3.1.1'
gem 'torquebox-messaging'
gem 'torquebox-configure'
gem "torquebox-rake-support", '~>3.1.1'
gem 'torquebox-capistrano-support', '~>3.1.1', :group => :development
gem 'capistrano', '~> 2.15.5'

gem 'smarter_csv'
gem 'edr', github: 'KYCK/edr'

gem "sentry-raven", :git => "https://github.com/getsentry/raven-ruby.git"

gem 'symbolize', '4.4.1'
gem 'foreigner'


gem "braintree"

gem 'roar-rails'
gem 'representable-cache'
gem 'cells'

gem 'naught'

gem 'axlsx'
gem 'prawn', '~> 1.0.0.rc2'
gem 'prawn-templates', '~> 0.0.3'
gem 'prawn-svg'
gem 'wisper'#, github: 'ruprict/wisper', branch: 'master'

gem 'omniauth_kyck', '0.0.2', git: "https://github.com/kyck-infi/omniauth_kyck.git", branch: 'master'

gem 'settingslogic'
gem 'chronic'

gem 'lograge'

gem 'kyck_api', git: "https://github.com/kyck-infi/kyck_api.git", branch:'master'
gem 'request_store'

gem "flip"

gem 'aws-sdk', '~> 1.43.1'

gem "bower-rails", "~> 0.8.3"

gem 'acts_as_paranoid'

gem "march_hare", "~> 2.7"
gem 'celluloid'
gem 'intercom-rails'

gem "apostle-rails"
gem "jquery-slick-rails", "~> 1.5.5"
gem 'exception_notification'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'
  gem "therubyrhino"

  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
  gem 'zurb-foundation', '~> 4.3.1'
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
end

#gem 'angular-rails-templates', github: 'dmathieu/angular-rails-templates'

group :test do
  gem 'database_cleaner'
  gem 'launchy'
  gem 'simplecov', '~> 0.9.0'
  gem 'chromedriver-helper'
  gem 'timecop'
  gem 'rubocop'
  gem 'guard-rubocop'
  gem 'pdf-inspector'
  gem 'moqueue'
end

group :development do
  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry'
  gem 'rb-fsevent'
  gem 'sextant'
  gem 'quiet_assets'
  gem 'meta_request'
  #gem 'better_errors'
  #gem 'binding_of_caller'
  #gem 'debugger'

  # ASTRONOMICALLY SPEEDS UP ASSET LOADING IN DEV ENV
  gem 'rails-dev-tweaks'
end

group :development, :test do
  gem 'rspec-rails', '2.14.2'
  gem 'guard', '1.8.3'
  gem 'guard-rspec', '3.1.0'
  gem 'guard-jruby-rspec', github: 'jkutner/guard-jruby-rspec'
  gem 'selenium-webdriver', '~> 2.35.1'
  gem 'theine'
  gem 'rspec-cells', '0.1.12'
  gem 'capybara'
  gem 'forgery'
  gem 'json_spec'
  gem 'factory_girl_rails'
  gem 'parallel_tests'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
