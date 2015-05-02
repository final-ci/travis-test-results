require 'travis/config'
require 'travis/support'

module Travis
  module TestResults
    class Config < Travis::Config
      define  amqp:          { vhost: "travisci.development", username: "travisci_worker", password: "travisci_worker_password"},
              test_results_database: { adapter: 'postgresql', database: "travis_#{Travis.env}", encoding: 'unicode', min_messages: 'warning' },
              test_results:          { threads: 10 }

      default _access: [:key]

      def env
        Travis.env
      end
    end
  end
end
