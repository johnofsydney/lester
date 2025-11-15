source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2' # out of date

gem 'rails', '~> 7.2'
gem 'sprockets-rails'
gem 'pg', '~> 1.1'
gem 'puma', '>= 6.4.3'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'redis', '~> 4.0'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ]
gem 'bootsnap', require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  # gem "bullet"
  gem 'rspec-rails', '~> 6.1.0'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'brakeman', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'rubocop-performance', require: false
  gem 'bundler-audit', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
end

gem 'dockerfile-rails', '>= 1.2', :group => :development
gem 'phlex-rails', '> 2'

gem 'pg_search'
gem 'devise'

gem 'sassc-rails'
gem 'activeadmin', '~> 3.3.0'

gem 'money-rails', '~> 1.12'
gem 'capitalize-names'

gem 'chartkick'
gem 'groupdate'

gem 'vite_rails'
gem 'inertia_rails'

gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'

# TODO:
# add bootstrap gem?
# https://dev.to/chmich/setup-bootstrap-on-rails-7-and-vite-g5a

gem 'faraday'
gem 'sidekiq'

gem 'newrelic_rpm'

# resolving vulnerabilities
gem 'rack', '>= 3.1.18'
gem 'uri', '~> 1.0.4'

gem 'sidekiq-unique-jobs'

# https://github.com/fatkodima/activerecord_lazy_columns
gem 'activerecord_lazy_columns'

gem "prettytodo"

gem 'sidekiq-scheduler'

gem 'selenium-webdriver', '~> 4.34'