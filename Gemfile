source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "rails", "~> 7.0.4", ">= 7.0.4.3"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", "~> 4.0"


# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"


gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "bullet"
  gem 'rspec-rails', '~> 6.1.0'
  gem 'shoulda-matchers', '~> 5.0'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
end


gem "dockerfile-rails", ">= 1.2", :group => :development
gem "phlex-rails"

gem 'pg_search'
gem 'devise'

gem "sassc-rails"
gem 'activeadmin'

gem 'money-rails', '~> 1.12'
gem 'capitalize-names'

gem "chartkick"
gem "groupdate"

gem 'vite_rails'
gem 'inertia_rails'

# TODO:
# add bootstrap gem?
# https://dev.to/chmich/setup-bootstrap-on-rails-7-and-vite-g5a