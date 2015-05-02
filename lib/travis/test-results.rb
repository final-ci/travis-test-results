require 'travis/test-results/config'

module Travis
  def self.config
    TestResults.config
  end

  module TestResults
    def self.config
      @config ||= Config.load
    end

    def self.database_connection=(connection)
      @database_connection = connection
    end

    def self.database_connection
      @database_connection
    end
  end
end
