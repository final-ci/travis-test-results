require 'sequel'
# require 'jdbc/postgres'
require 'delegate'
require 'active_support/core_ext/string/filters'

module Travis
  module TestResults
    module Helpers
      # The Database helper talks to the Postgres database.
      #
      # No database-specific logic (such as table names and SQL queries) should
      # be outside of this class.
      class Database
        # This method should only be called for "maintenance" tasks (such as
        # creating the tables or debugging).
        def self.create_sequel
          config = Travis::TestResults.config.test_results_database
          Sequel.connect(database_url, max_connections: config[:pool]).tap do |db|
            db.timezone = :utc
          end
        end

        def self.database_url
          Travis::TestResults.config.test_results_database.fetch(
            :url,
            ENV['DATABASE_URL'] || 'postgres://localhost:5432/travis_test_results_test'
          )
        end

        def self.connect
          new.tap(&:connect)
        end

        def initialize
          @db = self.class.create_sequel
        end

        def connect
          @db.test_connection
          @db.extension :pg_json
          @db << "SET application_name = 'test_results'"
          @db << "SET TIME ZONE 'UTC'"
          prepare_statements
        end

        def step_result_by_job_id(job_id)
          @db.call(:step_result_by_job_id, job_id: job_id)
        end

        def create_step_result(job_id, data)
          @db.call(:create_step_result,             job_id: job_id,
                                                    # uuid: uuid,
                                                    step_result: Sequel.pg_json(data),
                                                    created_at: Time.now.utc,
                                                    updated_at: Time.now.utc)
        end

        def transaction(&block)
          @db.transaction(&block)
        end

        private

        def prepare_statements
          @db[:step_results].where(job_id: :$job_id).prepare(:select, :step_result_by_job_id)
          @db[:step_results].prepare(:insert, :create_step_result,           job_id: :$job_id,
                                                                             # uuid: :$uuid,
                                                                             data: :$step_result,
                                                                             created_at: :$created_at,
                                                                             updated_at: :$updated_at)
          end
      end
    end
  end
end
