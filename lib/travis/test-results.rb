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

      attr_writer :database_connection

      attr_reader :database_connection
    end
  end
end
