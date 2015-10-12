#$: << 'lib'
#require 'travis/logs'
require 'travis/support'
require 'travis/support/amqp'
require 'travis/support/exceptions/reporter'
require 'travis/support/metrics'
require 'travis/test-results/receive/queue'
require 'travis/test-results/services/process_test_results'
require 'active_support/core_ext/logger'

$stdout.sync = true

module Travis
  module TestResults
    class Receive
      def setup
        Travis.logger.info('** Starting Test Results Processor **')
        Travis::Amqp.config = amqp_config
        Travis::Exceptions::Reporter.start
        Travis::Metrics.setup

        #ActiveRecord::Base.default_timezone = :utc
        #ActiveRecord::Base.logger = Travis.logger

        #ActiveRecord::Base.configurations = {
        #  'test_results_database' => Travis.config.test_results_database
        #}

        #ActiveRecord::Base.establish_connection('test_results_database')


        declare_exchanges
      end

      def run
        1.upto(TestResults.config.test_results.threads) do
          Queue.subscribe('test_results', Travis::TestResults::Services::ProcessTestResults)
        end
        sleep
      end

      def amqp_config
        Travis::TestResults.config.amqp.merge({
          :thread_pool_size => (TestResults.config.test_results.threads * 2 + 3)
        })
      end

      def declare_exchanges
        channel = Travis::Amqp.connection.create_channel
        channel.exchange 'reporting', durable: true, auto_delete: false, type: :topic
      end
    end
  end
end
