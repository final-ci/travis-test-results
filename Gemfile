source 'https://rubygems.org'

gem 'activesupport',      '~> 3.2'
gem 'travis-support',     github: 'finalci/travis-support'
gem 'travis-config',      '~> 0.1.0'

# just for now, needs to be rewriten, see
# .lib/travis/test-results/services/process_test_results.rb
gem 'travis-core',        github: 'finalci/travis-core', branch: 'feature/test_results_models'


platform :jruby do

  gem 'march_hare',         '~> 2.3.0'

  gem 'jdbc-postgres',      '9.3.1101'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbc-adapter'
end

platform :mri do
  gem 'bunny',            '~> 1.7.0'
  gem 'pg'
end

gem 'json',               '~> 1.8.0'

group :test do
  gem 'rspec',            '~> 2.14.1'
end
