require 'travis/test-results/config'
require 'travis/test-results/cache'

module Travis
  def self.config
    TestResults.config
  end

  module TestResults
    class << self
      def config
        @config ||= Config.load
      end

      def cache
        @cache ||= Travis::TestResults::Cache.new(
          config.test_results.gc_remove_after,
          config.test_results.gc_pooling_interval
        )
      end

      def database_connection=(connection)
        @database_connection = connection
      end

      def database_connection
        @database_connection
      end
    end
  end
end
