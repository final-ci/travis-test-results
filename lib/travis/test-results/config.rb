require 'travis/config'
require 'travis/support'

module Travis
  module TestResults
    class Config < Travis::Config
      define  amqp:          { vhost: "travisci.development", username: "travisci_worker", password: "travisci_worker_password", prefetch: 1},
              test_results_database: {
                adapter: 'postgresql',
                database: "travis_test_results_#{Travis.env}",
                encoding: 'unicode',
                min_messages: 'warning',
                url: 'postgres://localhost:5432/travis_test_results_test' 
              },
              test_results:          { threads: 10 },
              pusher:        { app_id: 'app-id', key: 'key', secret: 'secret', secure: false },
              sidekiq:       { namespace: 'sidekiq', pool_size: 3 },
              redis:         { url: 'redis://localhost:6379' },
              metrics:       { reporter: 'librato' },
              ssl:           { },
              sentry:        { }

      default _access: [:key]

      def env
        Travis.env
      end
    end
  end
end
