source 'https://rubygems.org'

gem 'activesupport',      '~> 3.2'
gem 'travis-support',     github: 'finalci/travis-support'
gem 'travis-config',      '~> 0.1.0'

# just for now, needs to be rewriten, see
# .lib/travis/test-results/services/process_test_results.rb
# gem 'travis-core',        github: 'finalci/travis-core' #, branch: 'feature/test_results_models'

gem 'sequel',             '~> 4.28.0'
gem 'pusher'
gem 'metriks'
gem 'sentry-raven', github: 'getsentry/raven-ruby'

gem 'connection_pool'

gem 'sidekiq'

gem 'bunny', '~> 1.7.0'
gem 'pg'

# gem 'json',               '~> 1.8.0'
gem 'multi_json'

gem 'sinatra', '~> 1.4'
gem 'rack-ssl'
gem 'puma'

group :test do
  gem 'rspec', '~> 2.14.1'
end

group :test, :development do
  gem 'rake'
  gem 'rack-test'
end
