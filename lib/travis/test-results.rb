require 'travis/test-results/config'

module Travis
  def self.config
    TestResults.config
  end

  module TestResults
    class << self
      def config
        @config ||= Config.load
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
