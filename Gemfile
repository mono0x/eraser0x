
source "http://rubygems.org"
ruby '2.1.0'

gem 'twitter', '~> 4.5.0'
gem 'userstream', :require => 'user_stream'
gem 'foreman'
gem 'rake'
gem 'data_mapper'
gem 'dm-migrations'

group :production do
  gem 'dm-postgres-adapter'
end

group :development do
  gem 'guard', :require => false
  gem 'guard-rspec', :require => false
  gem 'guard-bundler', :require => false
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'ruby_gntp', :require => false
  gem 'dm-sqlite-adapter'

  group :test do
    gem 'rspec'
    gem 'factory_girl'
    gem 'simplecov'
  end
end
